const { ethers,upgrades } = require("hardhat");

async function main() {
    const MyTokenUpgradeable = await ethers.getContractFactory("MyTokenUpgradeable");

    const mytokenupgradeable = await upgrades.deployProxy(MyTokenUpgradeable, {
        initializer: "initialize",
    });
    await mytokenupgradeable.deployed();
    console.log("token deployed to:", mytokenupgradeable.address);
}

main();