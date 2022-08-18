const {ethers,upgrades} = require("hardhat");

const PROXY = '0x1Bd5527B8597E560D39edE8D7D8e7e6c5d2dc430' // contract that has the storage

async function main() {
     const BoxV2 = await ethers.getContractFactory("BoxV2");
     await upgrades.upgradeProxy(PROXY, BoxV2);
     console.log('Box upgraded to BoxV2')
}

main();