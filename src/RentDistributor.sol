// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PropertyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RentDistributor is Ownable {
    event RentDeposited(uint indexed tokenId, uint amount);
    event RentClaimed(uint indexed tokenId, address indexed claimant, uint amount);

    PropertyToken public datapropertyToken;
    mapping(uint => mapping(address => uint)) public rentClaimed;
    mapping(uint => uint) public totalRentCollected; 

    constructor(address _propertyTokenAddress) Ownable(msg.sender) {
        datapropertyToken = PropertyToken(_propertyTokenAddress);
    }
    
    function depositRent(uint _tokenId, uint _amount) public onlyOwner(){
        PropertyRegistry.Property memory _property = datapropertyToken.getPropertyInfo(_tokenId);
        require(_property.availiable == true, "Property is not available");
        require(_amount > 0, "Amount must be greater than zero");
        require(datapropertyToken.token().transferFrom(msg.sender, address(this), _amount), "RentDistributor: Transfer failed");
        totalRentCollected[_tokenId] += _amount;
        emit RentDeposited(_tokenId, _amount);
    }

    function claimRent(uint _tokenId) public {
        PropertyRegistry.Property memory _property = datapropertyToken.getPropertyInfo(_tokenId);
        require(_property.availiable == true, "Property is not available");
        uint rentalOwed = (totalRentCollected[_tokenId] * datapropertyToken.balanceOf(msg.sender, _tokenId)) / _property.fractionsSold;
        uint rentToClaim = rentalOwed - rentClaimed[_tokenId][msg.sender];
        require(rentToClaim > 0, "No rent to claim");
        rentClaimed[_tokenId][msg.sender] = rentalOwed;
        require(datapropertyToken.token().transfer(msg.sender, rentToClaim), "RentDistributor: Transfer failed");
        emit RentClaimed(_tokenId, msg.sender, rentToClaim);
    }
}