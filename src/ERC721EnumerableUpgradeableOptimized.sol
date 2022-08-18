// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721UpgradeableOptimized.sol";
import "Openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "Openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 * @dev Optimized the shit outta this by taking out everything that isn't needed to remain compatable with existing ERC721 enumerables
 **/
abstract contract ERC721EnumerableUpgradeableOptimized is Initializable, ERC721UpgradeableOptimized, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721UpgradeableOptimized) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint count;
        for(uint i; i<_owners.length;){
            if(owner == _owners[i]){
                if(count == index) return i;
                else{unchecked{++count;}}
            }
            unchecked{++i;}
        }
        revert('ERC721EnumerableOptimized: index out of bounds');
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
    //     return _allTokens.length;
    // }
    // BECOMES
        return _owners.length;
    }
    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
