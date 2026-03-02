// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PropertyRegistry.sol";

/**
 * @title PropertyToken
 * @author Sebastián Duarte
 * @notice ERC-1155 token representing fractional ownership of real estate properties
 * @dev Each tokenId maps to a property in PropertyRegistry; supply = fractions
 */
contract PropertyToken is ERC1155, Ownable {
    // ═══════════════════ EVENTS ═══════════════════
    event FractionsPurchased(address indexed buyer, uint indexed tokenId, uint amount, uint cost);
    event FundsWithdrawn(address indexed owner, uint amount);

    // ═══════════════════ STATE ═══════════════════
    IERC20 public immutable token;
    PropertyRegistry public propertyRegistry;

    // ═══════════════════ CONSTRUCTOR ═══════════════════
    /// @param _propertyRegistry Address of the deployed PropertyRegistry
    /// @param _token Address of the ERC-20 stablecoin used for payments
    constructor(address _propertyRegistry, address _token) ERC1155("") Ownable(msg.sender) {
        propertyRegistry = PropertyRegistry(_propertyRegistry);
        token = IERC20(_token);
    }

    // ═══════════════════ CORE FUNCTIONS ═══════════════════

    /// @notice Purchase fractional tokens of a registered property
    /// @param _tokenId Property ID from the Registry
    /// @param _amount Number of fractions to purchase
    function purchaseFraction(uint _tokenId, uint _amount) public {
        PropertyRegistry.Property memory _property = propertyRegistry.getProperty(_tokenId);
        require(_property.available == true, "PropertyToken: property not available");
        require(
            _amount > 0 && _amount <= _property.totalFractions - _property.fractionsSold,
            "PropertyToken: invalid amount"
        );

        uint cost = _amount * _property.pricePerFraction;
        require(token.transferFrom(msg.sender, address(this), cost), "PropertyToken: payment failed");

        _mint(msg.sender, _tokenId, _amount, bytes(""));
        propertyRegistry.updateFractionsSold(_tokenId, _amount);

        emit FractionsPurchased(msg.sender, _tokenId, _amount, cost);
    }

    /// @notice Withdraw accumulated stablecoin funds from fraction sales (owner only)
    function withdrawFunds() public onlyOwner {
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "PropertyToken: no funds to withdraw");
        require(token.transfer(msg.sender, balance), "PropertyToken: transfer failed");

        emit FundsWithdrawn(msg.sender, balance);
    }

    // ═══════════════════ VIEW FUNCTIONS ═══════════════════

    /// @notice Get property data from the Registry (convenience wrapper)
    /// @param _tokenId Property ID to query
    /// @return Property struct with all property data
    function getPropertyInfo(uint _tokenId) public view returns (PropertyRegistry.Property memory) {
        return propertyRegistry.getProperty(_tokenId);
    }
}