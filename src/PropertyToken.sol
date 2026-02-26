// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./PropertyRegistry.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PropertyToken is ERC1155, Ownable{
    /*-------------------events--------------------------*/
    event FractionPurchase(uint _tokenId, uint _amount);

    IERC20 public immutable token;
    PropertyRegistry public datapropertyRegistry;

    constructor (address _propertyRegistry, address _token) ERC1155("") Ownable(msg.sender) {
        datapropertyRegistry = PropertyRegistry(_propertyRegistry);
        token = IERC20(_token);
    }
    function purchaseFraction(uint _tokenId, uint _amount) public {
        PropertyRegistry.Property memory _property = datapropertyRegistry.getProperty(_tokenId);
        require(_property.availiable == true,"PropertyToken: Unavailiable property");
        require(_amount >0 && _amount <= _property.totalFractions - _property.fractionsSold, "PropertyToken: Invalid amount");
        uint cost = _amount * _property.pricePerFraction;
        require(token.transferFrom(msg.sender, address(this), cost), "PropertyToken: Transfer failed");
        _mint(msg.sender, _tokenId, _amount, bytes(""));
        datapropertyRegistry.updateFractionsSold(_tokenId, _amount);
        emit FractionPurchase(_tokenId, _amount);
    }
    function withdrawFunds() public onlyOwner{
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "PropertyToken: No funds to commit");
        require(token.transfer(msg.sender, balance),"PropertyToken: Transfer failed");
    }
}