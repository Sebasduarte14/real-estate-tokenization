// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
contract PropertyRegistry is AccessControl{
/*-----------Events--------------*/
    event PropertyRegistered(uint indexed count,uint _totalFractions, uint _pricePerFraction);
    event PropertyCanceled (uint indexed _tokenId);
/*-----------Variables--------------*/
    struct Property {
        uint tokenId;
        uint totalFractions; 
        uint fractionsSold; 
        uint pricePerFraction;
        bool availiable;
        string metaDataUri;
    }
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");
    mapping (uint => Property) public property;
    uint public count ; 
/*-----------Construcotr--------------*/
    constructor () {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
/*-----------Pincipal Fuctions--------------*/
    function registerProperty (uint _totalFractions,
    uint _pricePerFraction, 
    string memory _metaDataUri
    ) 
    public 
    onlyRole(ADMIN_ROLE) {
        require(_totalFractions > 0, "PropertyRegistry: fractions must be greater than zero");
        require(_pricePerFraction > 0, "PropertyRegistry: price must be greater than zero");
        count = count + 1 ; 
        property[count] = Property(count,_totalFractions,0,_pricePerFraction,true,_metaDataUri);
        emit PropertyRegistered(count,_totalFractions, _pricePerFraction);
    }
    function getProperty(uint _tokenId) 
    external 
    view 
    returns 
    (Property memory) 
    {
        return property[_tokenId];
    }
    function desactivateProperty (uint _tokenId)
    public
    onlyRole(OPERATOR_ROLE)
    {
        Property storage _property = property[_tokenId];
        require(_property.tokenId != 0,"PropertyRegistry: the ID property does no exit" );
        require(_property.availiable == true, "PropertyRegistry: Property its unavailiable");
        _property.availiable = false;
        emit PropertyCanceled(_tokenId);
    }
    function updateFractionsSold(uint _tokenId, uint _amount) external onlyRole(TOKEN_MANAGER_ROLE) {
        Property storage _property = property[_tokenId];
        require(_property.availiable == true, "PropertyRegistry: Property its unavailiable");
        _property.fractionsSold += _amount;
    }
    function setTokenContract(address _tokenContract) external onlyRole(ADMIN_ROLE) {
    _grantRole(TOKEN_MANAGER_ROLE, _tokenContract);
    }
}


