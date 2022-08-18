// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
//uses UUPS for the proxy

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Barn Raise BeaNFT - opimized for farmers
/// @author Brean
/// @notice Mints NFTs, where rarity is based on time bought and size
/// @dev Based on Upgradable ERC721Enum with optimizations, uses merkle root to determine tokenIDs
contract MyERC721Upgradeable is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable,UUPSUpgradeable{
  bytes32 public root;
  string private _baseTokenURI;

  
  function initialize() external initializer {
    __ERC721_init('MOCK', 'MCK');
    __ERC721Enumerable_init();
    __Ownable_init();
    __merkle_init(0x70dd7486fac97f33c9d9961c5192c9a7870fb52ea07e6f151c18a2e38ca702d7);
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

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function batchMint(address to, uint256[] calldata tokenId,bytes32[] calldata merkle) public{
      require(checkValidity(tokenId, merkle));
      for(uint256 i; i <  tokenId.length;++i){
        _mint(to,tokenId[i]);
      }
    }

    function _safeBatchMint(address to, uint256[] memory tokenId) internal {
      for(uint256 i; i <  tokenId.length;++i){
          _safeMint(to,tokenId[i]);
        }
    }

    function mintBeaNFT(uint256[] calldata TokenID, bytes32[] calldata merkleProof) public{
      checkValidity(TokenID,merkleProof);
      if (TokenID.length == 1){
        _safeMint(msg.sender,TokenID[0]);
      }
      else{
        _safeBatchMint(msg.sender,TokenID);
      } 
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;


  //verify merkle
  function checkValidity(uint256[] calldata _tokenID,bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender,_tokenID));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Incorrect proof");
        return true; // Or you can mint tokens here
    }
}
