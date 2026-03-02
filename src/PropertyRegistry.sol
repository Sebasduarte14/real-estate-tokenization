// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PropertyRegistry
 * @author Sebastián Duarte
 * @notice Administrative registry for tokenized real estate properties
 * @dev Manages property data, roles, and cross-contract permissions
 */
contract PropertyRegistry is AccessControl {
    // ═══════════════════ EVENTS ═══════════════════
    event PropertyRegistered(uint indexed tokenId, uint totalFractions, uint pricePerFraction);
    event PropertyDeactivated(uint indexed tokenId);

    // ═══════════════════ STATE ═══════════════════
    struct Property {
        uint tokenId;
        uint totalFractions;
        uint fractionsSold;
        uint pricePerFraction;
        bool available;
        string metadataURI;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    mapping(uint => Property) public properties;
    uint public count;

    // ═══════════════════ CONSTRUCTOR ═══════════════════
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // ═══════════════════ ADMIN FUNCTIONS ═══════════════════

    /// @notice Register a new property for tokenization
    /// @param _totalFractions Total number of fractional tokens to create
    /// @param _pricePerFraction Price per fraction in stablecoin (smallest unit)
    /// @param _metadataURI IPFS URI pointing to property metadata (images, docs, location)
    function registerProperty(
        uint _totalFractions,
        uint _pricePerFraction,
        string memory _metadataURI
    ) public onlyRole(ADMIN_ROLE) {
        require(_totalFractions > 0, "PropertyRegistry: fractions must be greater than zero");
        require(_pricePerFraction > 0, "PropertyRegistry: price must be greater than zero");

        count++;
        properties[count] = Property(count, _totalFractions, 0, _pricePerFraction, true, _metadataURI);
        emit PropertyRegistered(count, _totalFractions, _pricePerFraction);
    }

    /// @notice Grant TOKEN_MANAGER_ROLE to the PropertyToken contract
    /// @param _tokenContract Address of the deployed PropertyToken
    function setTokenContract(address _tokenContract) external onlyRole(ADMIN_ROLE) {
        _grantRole(TOKEN_MANAGER_ROLE, _tokenContract);
    }

    // ═══════════════════ OPERATOR FUNCTIONS ═══════════════════

    /// @notice Deactivate a property (e.g., legal issues, sold off-chain)
    /// @param _tokenId ID of the property to deactivate
    function deactivateProperty(uint _tokenId) public onlyRole(OPERATOR_ROLE) {
        Property storage _property = properties[_tokenId];
        require(_property.tokenId != 0, "PropertyRegistry: property does not exist");
        require(_property.available == true, "PropertyRegistry: property already deactivated");

        _property.available = false;
        emit PropertyDeactivated(_tokenId);
    }

    // ═══════════════════ TOKEN MANAGER FUNCTIONS ═══════════════════

    /// @notice Update fractions sold count (called by PropertyToken on purchase)
    /// @param _tokenId ID of the property
    /// @param _amount Number of fractions sold
    function updateFractionsSold(uint _tokenId, uint _amount) external onlyRole(TOKEN_MANAGER_ROLE) {
        Property storage _property = properties[_tokenId];
        require(_property.available == true, "PropertyRegistry: property is not available");

        _property.fractionsSold += _amount;
    }

    // ═══════════════════ VIEW FUNCTIONS ═══════════════════

    /// @notice Get full property data (used by PropertyToken and RentDistributor)
    /// @param _tokenId ID of the property to query
    /// @return Property struct with all property data
    function getProperty(uint _tokenId) external view returns (Property memory) {
        return properties[_tokenId];
    }
}


