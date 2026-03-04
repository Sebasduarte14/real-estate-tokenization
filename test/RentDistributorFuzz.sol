// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/PropertyToken.sol";
import "../src/PropertyRegistry.sol";
import "../src/RentDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

contract RentDistributorFuzz is Test {
    PropertyToken public propertyToken;
    PropertyRegistry public propertyRegistry;
    RentDistributor public rentDistributor;
    MockUSDC public token;
    address admin = makeAddr("admin");
    address buyer = makeAddr("buyer");
    address operator = makeAddr("operator");
    address buyer2 = makeAddr("buyer2");

    function setUp() public {
        vm.startPrank(admin);
        propertyRegistry = new PropertyRegistry();
        propertyRegistry.registerProperty(10000, 50, " ");
        propertyRegistry.grantRole(propertyRegistry.OPERATOR_ROLE(), operator);
        vm.stopPrank();
        token = new MockUSDC(); 
        propertyToken = new PropertyToken(address(propertyRegistry),address(token));
        vm.prank(admin);
        propertyRegistry.setTokenContract(address(propertyToken));
        token.transfer(buyer, 100_000 * 10 ** 18);
        token.transfer(buyer2, 100_000 * 10 ** 18);
        rentDistributor = new RentDistributor(address(propertyToken));
    }
    function testFuzz_ClaimRent(uint _fractionToBuy, uint _rentAmount) public {
        vm.assume(_fractionToBuy>0 && _fractionToBuy<propertyRegistry.getProperty(1).totalFractions);
        vm.assume(_rentAmount>0 && _rentAmount <= 100_000 *10**18);
        vm.startPrank(buyer);
        token.approve(address(propertyToken), _fractionToBuy*50);
        propertyToken.purchaseFraction(1, _fractionToBuy);
        vm.stopPrank();
        token.approve(address(rentDistributor),_rentAmount);
        rentDistributor.depositRent(1, _rentAmount);
        vm.startPrank(buyer);
        rentDistributor.claimRent(1);
        vm.stopPrank();
        assertEq(rentDistributor.rentClaimed(1, buyer), _rentAmount);
    }
    function testFuzz_ClaimRentTwoHolders(uint fraction1, uint fraction2) public {
        fraction1 = bound(fraction1, 1, 9999);
        fraction2 = bound(fraction2, 1, 10000 - fraction1);
        vm.startPrank(buyer);
        token.approve(address(propertyToken), fraction1*50);
        propertyToken.purchaseFraction(1, fraction1);
        vm.stopPrank();
        vm.startPrank(buyer2);
        token.approve(address(propertyToken), fraction2*50);
        propertyToken.purchaseFraction(1, fraction2);
        vm.stopPrank();
        token.approve(address(rentDistributor), 10_000 * 10 ** 18);
        rentDistributor.depositRent(1, 10_000*10**18);
        vm.prank(buyer);
        rentDistributor.claimRent(1);
        vm.prank(buyer2);
        rentDistributor.claimRent(1);
        assertEq(10_000*10**18 * fraction2 / (propertyRegistry.getProperty(1).fractionsSold), rentDistributor.rentClaimed(1,buyer2));
    }
}