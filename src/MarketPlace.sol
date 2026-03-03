// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PropertyToken.sol";

/**
 * @title Marketplace
 * @author Sebastián Duarte
 * @notice Secondary market for trading fractional property tokens between users
 * @dev Sellers must call PropertyToken.setApprovalForAll(marketplace, true) before listing
 */
contract MarketPlace is Ownable {
    // ═══════════════════ EVENTS ═══════════════════
    event ListingCreated(uint indexed listingId, address indexed seller, uint tokenId, uint amount, uint pricePerFraction);
    event ListingCanceled(uint indexed listingId);
    event FractionPurchased(uint indexed listingId, address indexed buyer, uint amount, uint totalCost);

    // ═══════════════════ STATE ═══════════════════
    PropertyToken public propertyToken;

    struct Listing {
        uint tokenId;
        address seller;
        uint amount;
        uint pricePerFraction;
        bool active;
    }

    mapping(uint => Listing) public listings;
    uint public listingCount;

    // ═══════════════════ CONSTRUCTOR ═══════════════════
    /// @param _propertyToken Address of the deployed PropertyToken
    constructor(address _propertyToken) Ownable(msg.sender) {
        propertyToken = PropertyToken(_propertyToken);
    }

    // ═══════════════════ CORE FUNCTIONS ═══════════════════

    /// @notice Create a sell order for fractional tokens
    /// @dev Seller must have called PropertyToken.setApprovalForAll(marketplace, true) first
    /// @param _tokenId Property ID of the fractions being sold
    /// @param _amount Number of fractions to sell
    /// @param _pricePerFraction Asking price per fraction in stablecoin
    function createListing(uint _tokenId, uint _amount, uint _pricePerFraction) public {
        require(
            propertyToken.isApprovedForAll(msg.sender, address(this)),
            "Marketplace: seller must approve marketplace first"
        );
        require(propertyToken.balanceOf(msg.sender, _tokenId) >= _amount, "Marketplace: insufficient fractions");
        require(_amount > 0, "Marketplace: amount must be greater than zero");
        require(_pricePerFraction > 0, "Marketplace: price must be greater than zero");

        listingCount++;
        listings[listingCount] = Listing(_tokenId, msg.sender, _amount, _pricePerFraction, true);

        emit ListingCreated(listingCount, msg.sender, _tokenId, _amount, _pricePerFraction);
    }

    /// @notice Cancel an active listing (seller only)
    /// @param _listingId ID of the listing to cancel
    function cancelListing(uint _listingId) public {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Marketplace: listing is not active");
        require(listing.seller == msg.sender, "Marketplace: only seller can cancel");

        listing.active = false;
        emit ListingCanceled(_listingId);
    }

    /// @notice Purchase fractions from an active listing (partial buys supported)
    /// @param _listingId ID of the listing to buy from
    /// @param _amount Number of fractions to purchase
    function purchase(uint _listingId, uint _amount) public {
        Listing storage listing = listings[_listingId];
        require(listing.active, "Marketplace: listing is not active");
        require(_amount > 0 && _amount <= listing.amount, "Marketplace: invalid amount");

        uint totalCost = _amount * listing.pricePerFraction;
        require(
            propertyToken.token().transferFrom(msg.sender, listing.seller, totalCost),
            "Marketplace: payment failed"
        );
        propertyToken.safeTransferFrom(listing.seller, msg.sender, listing.tokenId, _amount, bytes(""));

        listing.amount -= _amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit FractionPurchased(_listingId, msg.sender, _amount, totalCost);
    }
}
