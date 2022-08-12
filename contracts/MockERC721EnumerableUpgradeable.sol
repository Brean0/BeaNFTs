// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
//uses UUPS for the proxy

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/


contract MyERC721Upgradeable is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable,UUPSUpgradeable{
  bytes32 public root;
  string private _baseTokenURI;

  
  function initialize() external initializer {
    __ERC721_init('MOCK', 'MCK');
    __ERC721Enumerable_init();
    __Ownable_init();
    __merkle_init(0x52ca7d470651af09f4a0c4e5e5f2f6c5669c3b6e5fe05991ae099e4e4f92c78e);
  }

  function __merkle_init(bytes32 _root) internal onlyInitializing {
    root = _root;
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) public {
        _baseTokenURI = newBaseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint256 tokenId,bytes32[] calldata merkle) public {
      require(checkValidity(merkle));
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId,bytes32[] calldata merkle) public {
        require(checkValidity(merkle));
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data,
        bytes32[] calldata merkle
    ) public {
      require(checkValidity(merkle));
        _safeMint(to, tokenId, _data);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function batchMint(address to, uint256[] memory tokenId,bytes32[] calldata merkle) public{
      require(checkValidity(merkle));
      for(uint256 i; i <  tokenId.length;++i){
        _mint(to,tokenId[i]);
      }
    }
    function safeBatchMint(address to, uint256[] memory tokenId,bytes32[] calldata merkle) public{
      require(checkValidity(merkle));
      for(uint256 i; i <  tokenId.length;++i){
        _safeMint(to,tokenId[i]);
      }
    }
    
    function mintBeanFT() public{
      bytes32 = 
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;


  //verify merkle
  function checkValidity(bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Incorrect proof");
        return true; // Or you can mint tokens here
    }


}
