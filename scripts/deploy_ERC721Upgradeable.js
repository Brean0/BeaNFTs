const { ethers,upgrades } = require("hardhat");

async function main() {
    const ERC721 = await ethers.getContractFactory("MyERC721UpgradeableOptimized");

    const erc721 = await upgrades.deployProxy(ERC721, {
        initializer: "initialize"
    });
    await erc721.deployed();
    console.log("ERC721 deployed to:", erc721.address);
}

main();