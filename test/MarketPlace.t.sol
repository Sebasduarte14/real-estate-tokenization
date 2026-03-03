// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/PropertyToken.sol";
import "../src/PropertyRegistry.sol";
import "../src/MarketPlace.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

contract MarketPlaceTest is Test {
    PropertyToken public propertyToken;
    PropertyRegistry public propertyRegistry;
    MarketPlace public marketplace;
    MockUSDC public token;
    address admin = makeAddr("admin");
    address buyer1 = makeAddr("buyer1");
    address buyer2 = makeAddr("buyer2");
    address bider = makeAddr("bider");

    function setUp() public {
        vm.startPrank(admin);
        propertyRegistry = new PropertyRegistry();
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.stopPrank();
        token = new MockUSDC();
        propertyToken = new PropertyToken(address(propertyRegistry), address(token));
        vm.prank(admin);
        propertyRegistry.setTokenContract(address(propertyToken));
        token.transfer(buyer1, 100_000 * 10 ** 18);
        token.transfer(buyer2, 100_000 * 10 ** 18);
        token.transfer(bider, 100_000 * 10 ** 18);
        vm.startPrank(buyer1);
        token.approve(address(propertyToken), 5000 * 50);
        propertyToken.purchaseFraction(1, 5000);
        vm.stopPrank();
        vm.startPrank(buyer2);
        token.approve(address(propertyToken), 5000 * 50);
        propertyToken.purchaseFraction(1, 5000);
        vm.stopPrank();
        marketplace = new MarketPlace(address(propertyToken));
    }

    function testCreateListing() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        vm.stopPrank();
        (, , , , bool active) = marketplace.listings(1);
        assertTrue(active);
    }

    function test_RevertIf_IsNotApproved() public {
        vm.prank(buyer1);
        vm.expectRevert();
        marketplace.createListing(1, 5000, 55);
    }

    function test_RevertIf_InsufficientBalance() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        vm.expectRevert();
        marketplace.createListing(1, 7000, 45);
        vm.stopPrank();
    }

    function test_RevertIf_IncorrectPrice() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        vm.expectRevert();
        marketplace.createListing(1, 2500, 0);
        vm.stopPrank();
    }

    function testCancelListing() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        marketplace.cancelListing(1);
        vm.stopPrank();
        (, , , , bool active) = marketplace.listings(1);
        assertFalse(active);
    }

    function test_RevertIf_ListingInactive() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        marketplace.cancelListing(1);
        vm.expectRevert();
        marketplace.cancelListing(1);
        vm.stopPrank();
    }

    function test_RevertIf_NotSeller() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        vm.stopPrank();
        vm.prank(buyer2);
        vm.expectRevert();
        marketplace.cancelListing(1);
    }

    function testPurchase() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        vm.stopPrank();
        vm.startPrank(bider);
        token.approve(address(marketplace), 1000 * 45);
        marketplace.purchase(1, 1000);
        vm.stopPrank();
        assertEq(propertyToken.balanceOf(bider, 1), 1000);
        (, , uint amount, , ) = marketplace.listings(1);
        assertEq(amount, 1500);
    }

    function test_RevertIf_PurchaseInactive() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        marketplace.cancelListing(1);
        vm.stopPrank();
        vm.startPrank(bider);
        token.approve(address(marketplace), 1000 * 45);
        vm.expectRevert();
        marketplace.purchase(1, 1000);
        vm.stopPrank();
    }

    function test_RevertIf_InvalidPurchaseAmount() public {
        vm.startPrank(buyer1);
        propertyToken.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(1, 2500, 45);
        vm.stopPrank();
        vm.startPrank(bider);
        token.approve(address(marketplace), 5000 * 45);
        vm.expectRevert();
        marketplace.purchase(1, 3000);
        vm.stopPrank();
    }
}