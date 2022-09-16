const { ethers, upgrades } = require('hardhat');
const fs = require('fs');

const PROXY = "0xa969BB19b1d35582Ded7EA869cEcD60A3Bd5D1E8";

async function main(){
    const BeaNFTV2 = await ethers.getContractFactory("ERC721ABean");
    console.log('Deploying...');
    await upgrades.upgradeProxy(PROXY,BeaNFTV2);
    console.log("BeaNFT Upgraded");
    
    const impl = await upgrades.erc1967.getImplementationAddress(PROXY);
    console.log("New Implmentation:",impl);

    try { 
        await run('verify', { address: impl });
    } catch (e) {}

}
main();