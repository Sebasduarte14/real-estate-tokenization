// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import "../src/PropertyToken.sol";
import "../src/PropertyRegistry.sol";
import "../src/RentDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";


contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }
}

contract Handler is Test {
    PropertyRegistry public propertyRegistry;
    PropertyToken public propertyToken;
    RentDistributor public rentDistributor;
    MockUSDC public token;
    address[] public holders;

    uint public totalRentDeposited;
    uint public totalFractionsSold;

    constructor() {
        propertyRegistry = new PropertyRegistry();
        propertyRegistry.registerProperty(10000, 50, " ");
        token = new MockUSDC();
        propertyToken = new PropertyToken(
            address(propertyRegistry), address(token)
        );
        propertyRegistry.setTokenContract(address(propertyToken));
        rentDistributor = new RentDistributor(address(propertyToken));

        for (uint i = 0; i < 3; i++) {
            address holder = makeAddr(string.concat("holder", vm.toString(i)));
            holders.push(holder);
            token.transfer(holder, 100_000 * 10 ** 18);
        }
    }
    function purchaseFraction(uint amount, uint holderSeed) public {
        uint available = propertyRegistry.getProperty(1).totalFractions
                       - propertyRegistry.getProperty(1).fractionsSold;
        if (available == 0) return;

        amount = bound(amount, 1, available);
        address holder = holders[holderSeed % holders.length];

        vm.startPrank(holder);
        token.approve(address(propertyToken), amount * 50);
        propertyToken.purchaseFraction(1, amount);
        vm.stopPrank();

        totalFractionsSold += amount;
    }
    function depositRent(uint amount) public {
        if (totalFractionsSold == 0) return; // Nadie compró, no tiene sentido depositar
        amount = bound(amount, 1, 10_000 * 10 ** 18);

        // El Handler es el owner del RentDistributor
        token.approve(address(rentDistributor), amount);
        rentDistributor.depositRent(1, amount);

        totalRentDeposited += amount;
    }
    function claimRent(uint holderSeed) public {
        address holder = holders[holderSeed % holders.length];
        uint balance = propertyToken.balanceOf(holder, 1);
        if (balance == 0) return; // No tiene fracciones, skip

        vm.prank(holder);
        rentDistributor.claimRent(1);
    }
}
contract RentDistributorInvariant is StdInvariant, Test {
    Handler public handler;

    function setUp() public {
        handler = new Handler();
        targetContract(address(handler));
    }

    function invariant_RentClaimedNeverExceedsDeposited() public view {
        uint totalClaimed = 0;
        for (uint i = 0; i < 3; i++) {
            totalClaimed += handler.rentDistributor().rentClaimed(
                1, handler.holders(i)
            );
        }
        assertLe(totalClaimed, handler.totalRentDeposited());
    }
}
