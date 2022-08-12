const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")
const { ethers } = require("ethers")

// List of 10 public Ethereum addresses
let addresses = [
    {"address":"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "uint256[]": [1]  },
    {"address":"0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "uint256[]": [2,4,6]  },
    {"address":"0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "uint256[]": [3,9,69,71]  },
    {"address":"0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "uint256[]": [4,10,510,132]  },
    {"address":"0x617F2E2fD72FD9D5503197092aC168c91465E7f2", "uint256[]": [5,129,231,452,290]  },
    {"address":"0x17F6AD8Ef982297579C203069C1DbfFE4348c372", "uint256[]": [6,20]  },
    {"address":"0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678", "uint256[]": [7,890]  },
    {"address":"0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7", "uint256[]": [8,327]  },
    {"address":"0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C", "uint256[]": [9,39]  },
    {"address":"0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC", "uint256[]": [10] },
    
    // {"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"},
    // {"0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"},
    // {"0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"},
    // {"0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"},
    // {"0x617F2E2fD72FD9D5503197092aC168c91465E7f2"},
    // {"0x17F6AD8Ef982297579C203069C1DbfFE4348c372"},
    // {"0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678"},
    // {"0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"},
    // {"0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C"},
    // {"0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC"},
]   

// Hash addresses to get the leaves
let leaves = addresses.map(addr => ethers.utils.solidityKeccak256(Object.keys(addr),Object.values(addr)))

// Create tree
let merkleTree = new MerkleTree(leaves, keccak256, {sortPairs: true})
// Get root
let rootHash = merkleTree.getRoot().toString('hex')

// Pretty-print tree
console.log(merkleTree.toString())

// 'Serverside' code
let hashedAddress = ethers.utils.solidityKeccak256(Object.keys(addresses[5]),Object.values(addresses[5]))
let proof = merkleTree.getHexProof(hashedAddress)
console.log(proof)

// Check proof
let v = merkleTree.verify(proof, hashedAddress, rootHash)
console.log(v) // returns true