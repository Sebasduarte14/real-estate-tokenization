// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/PropertyRegistry.sol";

contract PropertyRegistryTest is Test {
    PropertyRegistry public propertyRegistry;
    address admin = makeAddr("admin");
    address operator = makeAddr("operator");
    address tokenContract = makeAddr("tokenContract");
    address randomUser = makeAddr("randomUser");
    function setUp() public {
        vm.startPrank(admin);
        propertyRegistry = new PropertyRegistry();
        propertyRegistry.grantRole(propertyRegistry.OPERATOR_ROLE(), operator);
        vm.stopPrank();
    }
    function test_RevertIf_NonAdminRegisters() public {
    vm.prank(randomUser);
    vm.expectRevert();
    propertyRegistry.registerProperty(10000, 50, " ");
    }
    function testRegisterProperty() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000,50," ");
        assertEq(propertyRegistry.getProperty(1).available, true);
        assertEq(propertyRegistry.getProperty(1).fractionsSold,0);
        assertEq(propertyRegistry.getProperty(1).pricePerFraction,50);
        assertEq(propertyRegistry.getProperty(1).totalFractions,10000);
    }
    function test_RevertIf_FractionsAreZero() public {
        vm.prank(admin);
        vm.expectRevert();
        propertyRegistry.registerProperty(0,50," ");
    }
    function test_RevertIf_PriceIsZero() public {
        vm.prank(admin);
        vm.expectRevert();
        propertyRegistry.registerProperty(10000,0," ");
    }
    function testDesactiveProperty() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000,50," ");
        vm.prank(operator);
        propertyRegistry.deactivateProperty(1);
        assertFalse(propertyRegistry.getProperty(1).available);
    }
    function test_RevertIf_NoExists() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000,50," ");
        vm.prank(operator);
        vm.expectRevert();
        propertyRegistry.deactivateProperty(10000);
    }
    function test_RevertIf_IsUnAvailiable() public {
         vm.prank(admin);
        propertyRegistry.registerProperty(10000,50," ");
        vm.prank(operator);
        propertyRegistry.deactivateProperty(1);
        assertFalse(propertyRegistry.getProperty(1).available);
        vm.prank(operator);
        vm.expectRevert();
        propertyRegistry.deactivateProperty(1);
    }
    function testSetTokenContract() public {
        vm.prank(admin);
        propertyRegistry.setTokenContract(tokenContract);
        assertTrue(propertyRegistry.hasRole(propertyRegistry.TOKEN_MANAGER_ROLE(),tokenContract));
    }
    function testUpdateFractionSold() public {
        vm.prank(admin);
        propertyRegistry.setTokenContract(tokenContract);
        vm.prank(admin);
        propertyRegistry.registerProperty(10000,50," ");
        vm.prank(tokenContract);
        propertyRegistry.updateFractionsSold(1, 1000);
        assertEq(propertyRegistry.getProperty(1).fractionsSold, 1000);
    }
    function test_RevertIf_NonOperatorDeactivates() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.prank(randomUser);
        vm.expectRevert();
        propertyRegistry.deactivateProperty(1);
    }

    function test_RevertIf_NonTokenManagerUpdates() public {
        vm.prank(admin);
        propertyRegistry.registerProperty(10000, 50, " ");
        vm.prank(randomUser);
        vm.expectRevert();
        propertyRegistry.updateFractionsSold(1, 1000);
    }

    function test_RevertIf_NonAdminSetsTokenContract() public {
        vm.prank(randomUser);
        vm.expectRevert();
        propertyRegistry.setTokenContract(tokenContract);
    }
    
}

