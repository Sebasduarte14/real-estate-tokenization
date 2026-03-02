// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PropertyToken.sol";

/**
 * @title RentDistributor
 * @author Sebastián Duarte
 * @notice Distributes rental income proportionally to fractional property owners
 * @dev Uses pull-based distribution — holders claim their share based on token balance
 */
contract RentDistributor is Ownable {
    // ═══════════════════ EVENTS ═══════════════════
    event RentDeposited(uint indexed tokenId, uint amount);
    event RentClaimed(uint indexed tokenId, address indexed claimant, uint amount);

    // ═══════════════════ STATE ═══════════════════
    PropertyToken public propertyToken;

    /// @dev tokenId => holder => total rent already claimed
    mapping(uint => mapping(address => uint)) public rentClaimed;

    /// @dev tokenId => total rent deposited across all periods
    mapping(uint => uint) public totalRentCollected;

    // ═══════════════════ CONSTRUCTOR ═══════════════════
    /// @param _propertyTokenAddress Address of the deployed PropertyToken
    constructor(address _propertyTokenAddress) Ownable(msg.sender) {
        propertyToken = PropertyToken(_propertyTokenAddress);
    }

    // ═══════════════════ CORE FUNCTIONS ═══════════════════

    /// @notice Deposit rental income for a property (owner only, e.g., monthly rent)
    /// @param _tokenId Property ID receiving rental income
    /// @param _amount Amount of stablecoin to deposit as rent
    function depositRent(uint _tokenId, uint _amount) public onlyOwner {
        PropertyRegistry.Property memory _property = propertyToken.getPropertyInfo(_tokenId);
        require(_property.available == true, "RentDistributor: property not available");
        require(_amount > 0, "RentDistributor: amount must be greater than zero");
        require(
            propertyToken.token().transferFrom(msg.sender, address(this), _amount),
            "RentDistributor: transfer failed"
        );

        totalRentCollected[_tokenId] += _amount;
        emit RentDeposited(_tokenId, _amount);
    }

    /// @notice Claim proportional rental income based on fraction ownership
    /// @dev Formula: (totalRent * holderFractions / fractionsSold) - alreadyClaimed
    /// @param _tokenId Property ID to claim rent from
    function claimRent(uint _tokenId) public {
        PropertyRegistry.Property memory _property = propertyToken.getPropertyInfo(_tokenId);
        require(_property.available == true, "RentDistributor: property not available");
        require(_property.fractionsSold > 0, "RentDistributor: no fractions sold");

        uint holderBalance = propertyToken.balanceOf(msg.sender, _tokenId);
        require(holderBalance > 0, "RentDistributor: caller has no fractions");

        // Multiply before divide to preserve precision
        uint rentalOwed = (totalRentCollected[_tokenId] * holderBalance) / _property.fractionsSold;
        uint rentToClaim = rentalOwed - rentClaimed[_tokenId][msg.sender];
        require(rentToClaim > 0, "RentDistributor: no rent to claim");

        rentClaimed[_tokenId][msg.sender] = rentalOwed;
        require(
            propertyToken.token().transfer(msg.sender, rentToClaim),
            "RentDistributor: transfer failed"
        );

        emit RentClaimed(_tokenId, msg.sender, rentToClaim);
    }
}