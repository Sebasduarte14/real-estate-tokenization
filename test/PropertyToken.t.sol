// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/PropertyToken.sol";
import "../src/PropertyRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

contract PropertyTokenTest is Test {
    PropertyToken public propertyToken;
    PropertyRegistry public propertyRegistry;
    MockUSDC public token;
    address admin = makeAddr("admin");
    address buyer = makeAddr("buyer");

    function setUp() public{
        vm.startPrank(admin);
        propertyRegistry = new PropertyRegistry();
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.stopPrank();
        token = new MockUSDC();
        propertyToken = new PropertyToken(address(propertyRegistry),address(token));
        vm.prank(admin);
        propertyRegistry.setTokenContract(address(propertyToken));
        token.transfer(buyer, 100_000 * 10 ** 18);
    }
    function testPurchaseFraction() public {
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        propertyToken.purchaseFraction(1,1000);
        vm.stopPrank();
        assertEq(propertyRegistry.getProperty(1).fractionsSold, 1000);
        assertEq(propertyToken.balanceOf(buyer, 1), 1000);
    }
    function test_RevertIf_IsUnAvailiable() public {
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        vm.expectRevert();
        propertyToken.purchaseFraction(100,1000);
        vm.stopPrank();
    }
    function test_RevertIf_IsInvalidAmount() public {
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        vm.expectRevert();
        propertyToken.purchaseFraction(1,200000);
        vm.stopPrank();
    }
    function testWithdrawFunds() public {
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        propertyToken.purchaseFraction(1,1000);
        vm.stopPrank();
        propertyToken.withdrawFunds();
        assertEq(token.balanceOf(address(propertyToken)), 0);
    }
    function test_RevertIf_RandomWithdraw() public {
        vm.startPrank(buyer);
        token.approve(address(propertyToken),1000*50);
        propertyToken.purchaseFraction(1,1000);
        vm.expectRevert();
        propertyToken.withdrawFunds();
        vm.stopPrank();
    }
    function test_RevertIf_NoFunds() public {
        vm.expectRevert();
        propertyToken.withdrawFunds();
    }

}

