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

contract RentDistributorTest is Test {
    PropertyToken public propertyToken;
    PropertyRegistry public propertyRegistry;
    RentDistributor public rentDistributor;
    MockUSDC public token;
    address admin = makeAddr("admin");
    address buyer = makeAddr("buyer");
    address operator = makeAddr("operator");
    address random = makeAddr("random");

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
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        propertyToken.purchaseFraction(1,1000);
        vm.stopPrank();
        rentDistributor = new RentDistributor(address(propertyToken));
    }
    function testDepositRent() public {
        token.approve(address(rentDistributor), 1000 * 50);
        rentDistributor.depositRent(1, 1000*50);
        assertEq(rentDistributor.totalRentCollected(1),1000*50);
    }
    function test_RevertIf_NotOwnerDepositRent() public{
        vm.startPrank(buyer);
        token.approve(address(rentDistributor), 1000 * 50);
        vm.expectRevert();
        rentDistributor.depositRent(1, 1000 * 50);
        vm.stopPrank();
    }
    function test_RevertIf_DepositIsUnavailible() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.prank(operator);
        propertyRegistry.deactivateProperty(2);
        token.approve(address(rentDistributor), 1000 * 50);
        vm.expectRevert();
        rentDistributor.depositRent(2, 1000*50);
    }
    function test_RevertIf_InvalidAmount() public {
        vm.expectRevert();
        rentDistributor.depositRent(1, 0);
    }
    function testClaimRent() public {
        token.approve(address(rentDistributor), 1000 * 50);
        rentDistributor.depositRent(1, 1000*50);
        vm.prank(buyer);
        rentDistributor.claimRent(1);
        assertEq(rentDistributor.rentClaimed(1,buyer),1000*50);
    }
    function test_RevertIf_ClaimIsUnavailible() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.prank(operator);
        propertyRegistry.deactivateProperty(2);
        vm.startPrank(buyer);
        vm.expectRevert();
        rentDistributor.claimRent(2);
        vm.stopPrank();
    }
    function test_RevertIf_NoFractionsSold() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.expectRevert();
        rentDistributor.claimRent(2);
    }
    function test_RevertIf_Holderbalance0() public {
        token.approve(address(rentDistributor), 1000 * 50);
        rentDistributor.depositRent(1, 1000*50);
        vm.startPrank(random);
        vm.expectRevert();
        rentDistributor.claimRent(1);
        vm.stopPrank();
    }
    function test_RevertIf_NoRentToClaim() public {
        vm.startPrank(buyer);
        vm.expectRevert();
        rentDistributor.claimRent(1);
    }
}