// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
//uses UUPS for the proxy

import "./ERC721EnumerableUpgradeableOptimized.sol";
import "Openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "Openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "Openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Barn Raise BeaNFT - opimized for farmers
/// @author Brean
/// @notice Mints NFTs, where rarity is based on time bought and size
/// @dev Based on Upgradable ERC721Enum with optimizations, uses merkle root to determine tokenIDs
/// @dev 2 merkle trees are used to facilitate batch and partial mints for users
contract ERC721Bean is Initializable, ERC721EnumerableUpgradeableOptimized, OwnableUpgradeable, UUPSUpgradeable { 
  string private _baseTokenURI;
  bytes32 private root;
  
  function initialize() external initializer {
    __ERC721_init('BeaNFT Barn Raise', 'BEANFT');
    __ERC721Enumerable_init();
    __Ownable_init();
    //the root will be different, this is for testing using the test addresses on index.js
    __merkle_init(0x473f5af92c6c71bb5ed01d4dae89d73d0503180786926bba1462b0a61d5a4b33);
  }

  function __merkle_init(bytes32 _root) internal onlyInitializing {
    root = _root;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
  }

  function setBaseURI(string calldata newBaseTokenURI) external onlyOwner {
      _baseTokenURI = newBaseTokenURI;
  }

  function baseURI() public view returns (string memory) {
      return _baseURI();
  }

  function exists(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
  }

  function burn(uint256 tokenId) public {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
      _burn(tokenId);
  }
    
  /// @dev concatinates the tokenID array with address, and verifies that the user is whitelited for those mints
  // note this forces the user to mint all
  
  function mintAllBeaNFT(uint256[] calldata TokenID, bytes32[] calldata merkleProof) public {
    //only checks merkle tree once, vs checking multiple times per mint
    checkValidity(TokenID,merkleProof);
    if (TokenID.length == 1){
      _safeMint(_msgSender(),TokenID[0]);
    }
    else{
      _batchMint(_msgSender(),TokenID);
    } 
  }

  function checkValidity(uint256[] calldata _tokenID,bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(),_tokenID));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Incorrect proof");
        return true;
    }
   /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[49] private __gap;
}
