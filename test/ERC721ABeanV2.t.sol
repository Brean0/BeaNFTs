// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;
//test specific libraries
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";
import {IERC721EnumerableUpgradeable} from "Openzeppelin-contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "forge-std/console.sol";

//contract examples
import {UUPSProxy} from "../src/UUPSProxy.sol";
import {ERC721ABean} from "../src/ERC721ABeanV2/ERC721ABean.sol";

contract ERC721Test is DSTestPlus{
    UUPSProxy proxy;
    address proxyAddress;
    address admin;
    ERC721ABeanV2 token;

    function setUp() public {
    token = new ERC721ABeanV2();
    admin = hevm.addr(69);
    hevm.startPrank(admin);
    proxy = new UUPSProxy(address(token),"");
    address(proxy).call(abi.encodeWithSignature("initialize()"));
    hevm.stopPrank();
}

}