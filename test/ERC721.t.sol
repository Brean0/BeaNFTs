// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;
//test specific libraries
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {DSInvariantTest} from "./utils/DSInvariantTest.sol";
import {IERC721EnumerableUpgradeable} from "Openzeppelin-contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "forge-std/console.sol";

//contract examples
import {UUPSProxy} from "../src/UUPSProxy.sol";
import {ERC721Bean} from "../src/ERC721Bean.sol";
import {ERC721ReceiverMockUpgradeable} from "../src/ERC721ReceiverMockUpgradeable.sol";

//midway through, I realized there is no need to test the proxy, rather the implmentation instead 
// will keep it here for examples 
/// Merkle Tree data /// 
/* 
addresses = 
[
{"address":"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "uint256[]": [1]  },
{"address":"0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "uint256[]": [2,4,6]  },
{"address":"0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "uint256[]": [3,9,69,71]  },
{"address":"0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "uint256[]": [4,10,510,132]  },
{"address":"0x617F2E2fD72FD9D5503197092aC168c91465E7f2", "uint256[]": [5,129,231,452,290]  },
{"address":"0x17F6AD8Ef982297579C203069C1DbfFE4348c372", "uint256[]": [6,20]  },

{"address":"0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678", "uint256[]": [7,890]  },
{"address":"0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7", "uint256[]": [8,327]  },
]
*/
contract ERC721Recipient is ERC721ReceiverMockUpgradeable {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721ReceiverMockUpgradeable.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721ReceiverMockUpgradeable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721ReceiverMockUpgradeable.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721ReceiverMockUpgradeable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract ERC721Test is DSTestPlus {
    UUPSProxy proxy;
    address proxyAddress;
    address admin;
    ERC721Bean token;

    mapping (address => bytes32[]) public proofs;
    mapping (address => uint256[]) public whitelisted_mints;
    address[] public whitelist;
    uint256[10] public amt_minted;
    
    
    function setUp() public {
        token = new ERC721Bean();
        admin = hevm.addr(69);
        hevm.startPrank(admin);
        proxy = new UUPSProxy(address(token),"");
        address(proxy).call(abi.encodeWithSignature("initialize()"));
        hevm.stopPrank();
        //  MERKLE TESTING DATA ///// 
        // the addresses here are the ones on anvil
        
        whitelist = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
            0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
        ];
        //981 mints in total for 397 wallets
        //282 wallets that mint 1 (71%)
        //61 wallets that mint 2  (15.3%)
        //18 wallets that mint 3  (4.5%)
        //10 wallets that mint 4  (~3%)
        // above accounts for 93% of wallets, 
        //5 wallet that mint 5
        //3 wallets that mint 6
        //2 wallets that mint 7,8,9,15
        //1 wallet that will mint 11,14,18,20,21,28,50,60,77

        //to best see how this is used (for gas), we simulate with addresses that can mint: 1,2,3,4,5,6,10,20,50, and 77

        whitelisted_mints[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] =[0];
        whitelisted_mints[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] =[1,2];
        whitelisted_mints[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] =[3,4,5];
        whitelisted_mints[0x90F79bf6EB2c4f870365E785982E1f101E93b906] =[6,7,8,9];
        whitelisted_mints[0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65] =[10,11,12,13,14];
        whitelisted_mints[0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc] =[15,16,17,18,19,20];
        whitelisted_mints[0x976EA74026E726554dB657fA54763abd0C3a0aa9] =[21,22,23,24,25,26,27,28,29,30];
        whitelisted_mints[0x14dC79964da2C08b23698B3D3cc7Ca32193d9955] =[31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50];
        whitelisted_mints[0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f] =[51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100];
        whitelisted_mints[0xa0Ee7A142d267C1f36714E4a8F75612F20a79720] =[101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177];
                
        proofs[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] =[bytes32(0x5aa2e6b3a9fb920bab85247538ff2df2a59db5cd3bbc84e993c79a42968a0378),0x3e6b2d76e029004c8163ebd90f25841070ce726ab757e41137766696475d22bd,0xf6009025de09b69760f3ddd2e14e0f4ada0da2a9d337c9160a2f5d674b73a200,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] =[bytes32(0x8d7516f92f86ff2bff7638117eeefe54f86ce065a68c3b0f6c4b3d9bfb491ad6),0x3e6b2d76e029004c8163ebd90f25841070ce726ab757e41137766696475d22bd,0xf6009025de09b69760f3ddd2e14e0f4ada0da2a9d337c9160a2f5d674b73a200,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] =[bytes32(0xfd7a182e262d6a04eb5e191354c4d0ae72672bb14ede34520366d672eec83dc1),0x9fa282c55071f5db02703247131e9d7f7b02f4a9a850c49a751d57df59d52ea2,0xf6009025de09b69760f3ddd2e14e0f4ada0da2a9d337c9160a2f5d674b73a200,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x90F79bf6EB2c4f870365E785982E1f101E93b906] =[bytes32(0x246edf5a519f087f908654a67b5f5a6c8e2f6287a365a9f1ea113416c0a20f94),0x9fa282c55071f5db02703247131e9d7f7b02f4a9a850c49a751d57df59d52ea2,0xf6009025de09b69760f3ddd2e14e0f4ada0da2a9d337c9160a2f5d674b73a200,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65] =[bytes32(0xa95e4d99639a8904ceb7b4531e84015bad7d70cabaf7d02e590ae9f6ed603799),0x71ccde4277d66f792ff7cbff0f5cb783c84e64ce925fa9e81335843ac9d67f11,0xa745051c2b93841b68e1d69880248a0379bdb5dae3f4d495066b7ce877f7a835,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc] =[bytes32(0x33e5d5b80c5340acd6cd2a15f3a1ac680f5f7700c74cfb5ae67c3f36392f093c),0x71ccde4277d66f792ff7cbff0f5cb783c84e64ce925fa9e81335843ac9d67f11,0xa745051c2b93841b68e1d69880248a0379bdb5dae3f4d495066b7ce877f7a835,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x976EA74026E726554dB657fA54763abd0C3a0aa9] =[bytes32(0x267747b5f2d204fc5813b718e604aa624dad9e3206f5470aed8228748a593ab1),0x59f4ee3d782be10212ae02adbac702dd2b4f48c7be63f8e0b855925eb7147afa,0xa745051c2b93841b68e1d69880248a0379bdb5dae3f4d495066b7ce877f7a835,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x14dC79964da2C08b23698B3D3cc7Ca32193d9955] =[bytes32(0xe6d7cda6f3dc3aacf0c4309bb62d42156ca0450435c2eaa6914df7de496a204d),0x59f4ee3d782be10212ae02adbac702dd2b4f48c7be63f8e0b855925eb7147afa,0xa745051c2b93841b68e1d69880248a0379bdb5dae3f4d495066b7ce877f7a835,0xcba937dd510014990b175a1187bc2b81453b42cb9f2f2eed61024f2236c2a22e];
        proofs[0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f] =[bytes32(0x7503d268e46860bb62dafe2e5eca7b923b2f3adfbf028ed78bf95ba7633fc40e),0x294c3f7600b8c0a7558fa60b6958414895ae5c162b02dd26534a1df94179a6c8];
        proofs[0xa0Ee7A142d267C1f36714E4a8F75612F20a79720] =[bytes32(0xd7cb8c40697c7b872868079d94e037964f49e09ca5e88eb4c29f585e9289e261),0x294c3f7600b8c0a7558fa60b6958414895ae5c162b02dd26534a1df94179a6c8];

    }

    function testInvariantMetadata() public {
        //NAME
        (bool success, bytes memory _name) = address(proxy).call(
            abi.encodeWithSignature("name()"));
        assertTrue(success);
        assertEq(abi.decode(_name, (string)),"BeaNFT Barn Raise");

        //SYMBOL
        (bool success_2 ,bytes memory _symbol) = address(proxy).call(
            abi.encodeWithSignature("symbol()"));
        assertTrue(success_2);
        assertEq(abi.decode(_symbol, (string)),"BEANFT");
    }

    function testWhitelistedUserCanMint() public {
        //MINT
        address test_address = whitelist[0];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //balanceOf
        //console.log("balance of user should equal array length of user mint whitelist");
        (, bytes memory data) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",test_address)
        );

        assertEq(abi.decode(data, (uint256)), whitelisted_mints[test_address].length);
        
        //ownerOf
        //console.log("ownerOf NFT minted should be the whitelisted address");
        (,data) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",whitelisted_mints[test_address][0])
        );

        assertEq(abi.decode(data,(address)), test_address);

    }

    function testNonWhitelistedUserCannotMint() public {

        address test_address = address(0xDEADBEEF);
        hevm.prank(test_address);
        hevm.expectRevert(bytes("[FAIL. Reason: Index out of bounds]"));
        
        //mint
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );



        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSignature(
                "balanceOf(address)",
                test_address)
        );

        //console.log("balance of user should equal array length of user mint whitelist");
        assertEq(abi.decode(data, (uint256)), whitelisted_mints[test_address].length);
    }

    function testUserCanBurnNFT() public {
        //mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //burn NFT
        address(proxy).call(abi.encodeWithSignature(
            "burn(uint256)",
            whitelisted_mints[test_address][0])
        );

        //console.log("balance of user should equal 0");
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSignature("balanceOf(address)",
            test_address));
    
        assertEq(abi.decode(data, (uint256)), 0);

        hevm.expectRevert("ERC721: invalid token ID");
        (,data) = address(proxy).call(
            abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0]));

        hevm.stopPrank();
    }

    function testApprove() public {
        // Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(0xDEADBEEF),
            whitelisted_mints[test_address][0]));
        hevm.stopPrank();
        
        //getApproved
        (,bytes memory data) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );

        //check that the address is approved
        assertEq(abi.decode(data,(address)), address(0xDEADBEEF));
    }

    function testApproveAll() public {
        //mint
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //setApprovalForAll
        address(proxy).call(abi.encodeWithSignature
        ("setApprovalForAll(address,bool)",
         address(0xDEADBEEF),true));

        hevm.stopPrank();

        //isApprovedForAll
       (,bytes memory data) = address(proxy).call(
        abi.encodeWithSignature("isApprovedForAll(address,address)",
        test_address,address(0xDEADBEEF)));
        
        //check that the address is approved
        assertTrue(abi.decode(data,(bool)));
    }

    function testTransferFromNonOwnerAddress() public {
        //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );


        
        //approve -- Via test_address prank
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(this),whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();

        //stop prank, transfer from address1 to address2
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );
        
        //getApproved
        (,bytes memory removeApproval) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );
        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            address(0xDEADBEEF))
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

        assertEq(abi.decode(removeApproval,(address)), address(0));
        assertEq(abi.decode(newNFTOwner,(address)), address(0xDEADBEEF));
        assertEq(abi.decode(balance_new,(uint256)), 1);
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }

    function testTransferFromSelf() public {
        //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(this),whitelisted_mints[test_address][0])
        );

        //stop prank, transfer from address1 to address2 via Self
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();

        //getApproved
        (,bytes memory removeApproval) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );
        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            address(0xDEADBEEF))
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

        assertEq(abi.decode(removeApproval,(address)), address(0));
        assertEq(abi.decode(newNFTOwner,(address)), address(0xDEADBEEF));
        assertEq(abi.decode(balance_new,(uint256)), 1);
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }
    
   
    function testTransferFromApproveAll() public {
          //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );


        
        //setApprovalForAll
        address(proxy).call(abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            address(0xDEADBEEF),true)
        );
        hevm.stopPrank();

        //stop prank, transfer from address1 to address2
        //transferFrom
        hevm.prank(address(0xDEADBEEF));
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );

        //isApprovedForAll
        (,bytes memory isAllApproved) = address(proxy).call(
        abi.encodeWithSignature("isApprovedForAll(address,address)",
        test_address,address(0xDEADBEEF)));

        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            address(0xDEADBEEF))
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

        assertTrue(abi.decode(isAllApproved,(bool)));
        assertEq(abi.decode(newNFTOwner,(address)), address(0xDEADBEEF));
        assertEq(abi.decode(balance_new,(uint256)), 1);
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }

    function testSafeTransferFromToEOA() public {
          //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(this),whitelisted_mints[test_address][0])
        );

        //stop prank, transfer from address1 to address2 via Self
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();

        //getApproved
        (,bytes memory getApproved) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );
        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            address(0xDEADBEEF))
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

        assertEq(abi.decode(getApproved,(address)), address(0));
        assertEq(abi.decode(newNFTOwner,(address)), address(0xDEADBEEF));
        assertEq(abi.decode(balance_new,(uint256)), 1);
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        ERC721Recipient recipient = new ERC721Recipient();
          //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            recipient,whitelisted_mints[test_address][0])
        );

        //stop prank, transfer from address1 to address2 via Self
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            test_address,recipient,whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();

        //getApproved
        (,bytes memory getApproved) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );
        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            recipient)
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

         
        //confirm approvals are 0'd 
        assertEq(abi.decode(getApproved,(address)), address(0));
        //confirm new owner is recipient
        assertEq(abi.decode(newNFTOwner,(address)), address(recipient));
        //confirm new balance is 1
        assertEq(abi.decode(balance_new,(uint256)), 1);
        //confirm old balance is 0
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }
    
    function testSafeTransferFromToERC721RecipientWithData() public {
        ERC721Recipient recipient = new ERC721Recipient();
          //MINT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            recipient,whitelisted_mints[test_address][0])
        );

        //stop prank, transfer from address1 to address2 via Self
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256,bytes)",
            test_address,recipient,whitelisted_mints[test_address][0],"testing 123")
        );
        hevm.stopPrank();

        //getApproved
        (,bytes memory getApproved) = address(proxy).call(abi.encodeWithSignature(
            "getApproved(uint256)",
            whitelisted_mints[test_address][0])
        );
        //ownerOf
        (,bytes memory newNFTOwner) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",
            whitelisted_mints[test_address][0])
        );
        
        //balanceOf
        (,bytes memory balance_new) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            recipient)
        );

        //balanceOf
        (,bytes memory balance_old) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",
            test_address)
        );

         
        //confirm approvals are 0'd 
        assertEq(abi.decode(getApproved,(address)), address(0));
        //confirm new owner is recipient
        assertEq(abi.decode(newNFTOwner,(address)), address(recipient));
        //confirm new balance is 1
        assertEq(abi.decode(balance_new,(uint256)), 1);
        //confirm old balance is 0
        assertEq(abi.decode(balance_old,(uint256)), 0);
    }
    //general simulation of minting all wallets, allows better estimation
    function testBatchMint() public {
        // simulates all the mintooors 
        uint256 _whitelist = whitelist.length;
        for(uint256 i;i< _whitelist;++i){
            hevm.prank(address(whitelist[i]));
            address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[whitelist[i]],proofs[whitelist[i]])
        );
        }
    }
    // only 1 mint
    function testBatchMint1() public {
        //mint NFT
        address test_address = whitelist[0];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
    }
    // 2 mints
    function testBatchMint2() public {
        //mint NFT
        address test_address = whitelist[1];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
    }
    // 3 mints
    function testBatchMint3() public {
        //mint NFT
        address test_address = whitelist[2];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
    } 
    // 4 mints
    function testBatchMint4() public {
        //mint NFT
        address test_address = whitelist[3];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
    }
    // 20 mints
    function testBatchMint20() public {
        //mint NFT
        address test_address = whitelist[7];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
    }
    // 50 mints
    function testBatchMint50() public {
        //mint NFT
        address test_address = whitelist[8];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
    }
    // 77 mints
    function testBatchMint77() public {
        //mint NFT
        address test_address = whitelist[9];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        
    }
    //TEST FAILS
    function testCannotDoubleBurn() public {
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //burn NFT
        address(proxy).call(abi.encodeWithSignature(
            "burn(uint256)",
            whitelisted_mints[test_address][0])
        );
        
       //burn NFT
        hevm.expectRevert("ERC721: operator query for nonexistent token");
        address(proxy).call(abi.encodeWithSignature(
            "burn(uint256)",
            whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();

    }
    function testCannotBurnWhenNotApproved() public {
        address test_address = whitelist[0];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        //burn NFT
        hevm.prank(address(0xDEADBEEF));
        hevm.expectRevert(bytes("ERC721: caller is not token owner nor approved"));
        address(proxy).call(abi.encodeWithSignature(
            "burn(uint256)",
            whitelisted_mints[test_address][0])
        );
        

    }
    function testCannotApproveUnMinted() public {
        address test_address = whitelist[0];
        hevm.expectRevert("ERC721: operator query for nonexistent token");
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(0xDEADBEEF),
            whitelisted_mints[test_address][0]));
    }

    function testCannotApproveUnAuthorized() public {
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
         hevm.expectRevert("ERC721: operator query for nonexistent token");
        //approve
        address(proxy).call(abi.encodeWithSignature(
            "approve(address,uint256)", 
            address(0xDEADBEEF),
            whitelisted_mints[test_address][0]));
    }

    function testCannotTransferFromUnOwned() public {
        address test_address = whitelist[0];
        hevm.expectRevert("ERC721: operator query for nonexistent token");
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );
    }

    function testCannotTransferFromWrongFrom() public {
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert("ERC721: operator query for nonexistent token");
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            address(0xFEED), address(0xBEEF),whitelisted_mints[test_address][0])
        );
    }

    function testCannotTransferFromToZero() public {
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert("ERC721: operator query for nonexistent token");
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address, address(0),whitelisted_mints[test_address][0])
        );
    }

    function testCannotTransferFromNotOwner() public {
        //Mint NFT
        address test_address = whitelist[0];
        hevm.prank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );

        hevm.prank(address(0xDEADBEEF));
        hevm.expectRevert(bytes("ERC721: caller is not token owner nor approved"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            test_address,address(0xDEADBEEF),whitelisted_mints[test_address][0])
        );
    }

    function testCannotSafeTransferFromToNonERC721Recipient() public {
        //Mint NFT
        NonERC721Recipient nonERC721Recipent = new NonERC721Recipient();
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("ERC721: transfer to non ERC721Receiver implementer"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            test_address,address(nonERC721Recipent),whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();
    }

    function testCannotSafeTransferFromToNonERC721RecipientWithData() public {
        NonERC721Recipient nonERC721Recipent = new NonERC721Recipient();
        //Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("ERC721: transfer to non ERC721Receiver implementer"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256,bytes)",
            test_address,nonERC721Recipent,whitelisted_mints[test_address][0],"Testing 123")
        );
        hevm.stopPrank();
    }

    function testCannotSafeTransferFromToRevertingERC721Recipient() public {
        RevertingERC721Recipient revertingERC721Recipient = new RevertingERC721Recipient();
        //Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("z"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            test_address,revertingERC721Recipient,whitelisted_mints[test_address][0])
        );
        hevm.stopPrank();
    }

    function testCannotSafeTransferFromToRevertingERC721RecipientWithData() public {
        RevertingERC721Recipient revertingERC721Recipient = new RevertingERC721Recipient();
        //Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("z"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256,bytes)",
            test_address,revertingERC721Recipient,whitelisted_mints[test_address][0],"Testing 123")
        );
        hevm.stopPrank();
    }

    function testCannotSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        WrongReturnDataERC721Recipient wrongReturnDataERC721Recipient = new WrongReturnDataERC721Recipient();
        //Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("ERC721: transfer to non ERC721Receiver implementer"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            test_address,wrongReturnDataERC721Recipient,whitelisted_mints[test_address][0])
        );
    }

    function testCannotSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        WrongReturnDataERC721Recipient wrongReturnDataERC721Recipient = new WrongReturnDataERC721Recipient();
        //Mint NFT
        address test_address = whitelist[0];
        hevm.startPrank(test_address);
        address(proxy).call(abi.encodeWithSignature(
            "mintAllBeaNFT(uint256[],bytes32[])",
            whitelisted_mints[test_address],proofs[test_address])
        );
        hevm.expectRevert(bytes("ERC721: transfer to non ERC721Receiver implementer"));
        //transferFrom
        address(proxy).call(abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256,bytes)",
            test_address,wrongReturnDataERC721Recipient,whitelisted_mints[test_address][0],"testing 123"    )
        );
    }

    function testCannotBalanceOfZeroAddress() public {
        //balanceOf
        hevm.expectRevert(bytes("ERC721: address zero is not a valid owner"));
        (, bytes memory data) = address(proxy).call(abi.encodeWithSignature(
            "balanceOf(address)",address(0))
        );
    }

    function testCannotOwnerOfUnminted() public {
        hevm.expectRevert("ERC721: invalid token ID");
        (, bytes memory data) = address(proxy).call(abi.encodeWithSignature(
            "ownerOf(uint256)",1)
        );
    }
    
    // these address's pertain to contract addresses, but with the current test setup, cannot be tested
    // addtiionally, further verifications that all contracts were EOA will let us know whether this is useful to test
    /*
    //cant check yet
    // function testFailSafeMintToNonERC721Recipient() public {
    //     token.safeMint(address(new NonERC721Recipient()), 1337);
    // }

    // function testFailSafeMintToNonERC721RecipientWithData() public {
    //     token.safeMint(address(new NonERC721Recipient()), 1337, "testing 123");
    // }

    // function testFailSafeMintToRevertingERC721Recipient() public {
    //     token.safeMint(address(new RevertingERC721Recipient()), 1337);
    // }

    // function testFailSafeMintToRevertingERC721RecipientWithData() public {
    //     token.safeMint(address(new RevertingERC721Recipient()), 1337, "testing 123");
    // }

    // function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
    //     token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337);
    // }

    // function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
    //     token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    // }
     // need an address thats an non EOA to do this
    // function testSafeMintToERC721Recipient() public {
    //     ERC721Recipient to = new ERC721Recipient();

    //     token.safeMint(address(to), 1337);

    //     assertEq(token.ownerOf(1337), address(to));
    //     assertEq(token.balanceOf(address(to)), 1);

    //     assertEq(to.operator(), address(this));
    //     assertEq(to.from(), address(0));
    //     assertEq(to.id(), 1337);
    //     assertBytesEq(to.data(), "");
    // }

    // function testSafeMintToERC721RecipientWithData() public {
    //     ERC721Recipient to = new ERC721Recipient();

    //     token.safeMint(address(to), 1337, "testing 123");

    //     assertEq(token.ownerOf(1337), address(to));
    //     assertEq(token.balanceOf(address(to)), 1);

    //     assertEq(to.operator(), address(this));
    //     assertEq(to.from(), address(0));
    //     assertEq(to.id(), 1337);
    //     assertBytesEq(to.data(), "testing 123");
    // }
    */
}