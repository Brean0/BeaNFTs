const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")
const { ethers } = require("ethers")

const csv=require('csvtojson')
const csvFilePath='./BeaNFT_rank.csv'

csv()
.fromFile(csvFilePath)
.then((jsonObj)=>{
    console.log(jsonObj);
})

const jsonArray= csv().fromFile(csvFilePath);

// Example Merkle Tree Creator
// List of 10 public Ethereum addresses, from Anvil LocalHost
var whitelist = [
    '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
    '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
    '0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc',
    '0x976EA74026E726554dB657fA54763abd0C3a0aa9',
    '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955',
    '0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f',
    '0xa0Ee7A142d267C1f36714E4a8F75612F20a79720'
];

// Creates an Array of whitelisted mints containing an Address => uint256[] Object
// Criteria - Farmers who have bought more than 1000 fertilizer before replant

const whitelisted_mints = []
var amt_minted = [1,2,3,4,5,6,10,20,50,77];
var count = 0;
for(var i =0;i<amt_minted.length; ++i){
    var test_array = []
    for(var j = 0; j< amt_minted[i]; ++j){
        test_array.push(count);
        ++count;
    }
    
    //console.log(test_array);
    let entry = {"address": whitelist[i], "uint256[]" : test_array}
    whitelisted_mints.push(entry);
}
//console.log(whitelisted_mints);

//the result of this will let you put this on solidity
//for(var i=0;i<whitelist.length;++i){
//    console.log('proofs[' + Object.values(whitelisted_mints[i])[0] + '] =[' + Object.values(whitelisted_mints[i])[1] + "];" );
//    }


// We then Hash addresses to get the leaves
let leaves = whitelisted_mints.map(addr => ethers.utils.solidityKeccak256(Object.keys(addr),Object.values(addr)))

// Create tree
let merkleTree = new MerkleTree(leaves, keccak256, {sortPairs: true})
// Get root
let rootHash = merkleTree.getRoot().toString('hex')

// Pretty-print tree
console.log(merkleTree.toString())

// 'Serverside' code to get merkle proof
const proof_array = [];
const hasedAddress_array = []
for(var i=0; i<whitelisted_mints.length;++i){
    let hashedAddress = ethers.utils.solidityKeccak256(Object.keys(whitelisted_mints[i]),Object.values(whitelisted_mints[i]));
    hasedAddress_array.push(hashedAddress);
    let proof = (merkleTree.getHexProof(hashedAddress));
    let proof_entry = {"address": whitelist[i], "bytes32[]" : proof, "hashedAddress":hashedAddress};
    proof_array.push(proof_entry);

};
//simple Proof to verify that you are able to mint: 
console.log(Object.values(proof_array[0])[0]);
console.log(Object.values(proof_array[0])[1]);
let v = merkleTree.verify(Object.values(proof_array[0])[1], Object.values(proof_array[0])[2], rootHash);
console.log(v);

//the result of this will let you put this on solidity
// for(var i=0;i<whitelist.length;++i){
// console.log('proofs[' + Object.values(proof_array[i])[0] + '] =[' + Object.values(proof_array[i])[1] + "];" );
// };