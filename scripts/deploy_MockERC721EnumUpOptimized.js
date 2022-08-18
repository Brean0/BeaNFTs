const { ethers,upgrades } = require("hardhat");

async function main() {
    const ERC721Optimized = await ethers.getContractFactory("MyERC721UpgradeableOptimized");

    const erc721Optimized = await upgrades.deployProxy(ERC721Optimized, {
        initializer: "initialize"
    });
    await erc721Optimized.deployed();
    console.log("ERC721 deployed to:", erc721Optimized.address);
}

main();