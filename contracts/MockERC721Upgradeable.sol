// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
/*
prgioxy --> implementation
  ^
  |
  |
proxy admin
*/


contract MyERC721Upgradeable is Initializable, OwnableUpgradeable, ERC721Upgradeable {

   function initialize() external initializer {
        __ERC721_init('MOCK', 'MCK');
        __Ownable_init();
    }

    function mint(address to, uint amount) external onlyOwner{
      _mint(to,amount);
    }
}