import fs from "fs";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";
<<<<<<< HEAD
import '@nomiclabs/hardhat-truffle5';
import "hardhat-gas-reporter";
=======
//import '@nomiclabs/hardhat-truffle5';
import "hardhat-gas-reporter";
require("dotenv").config();
>>>>>>> dev

import example from "./tasks/example";

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim().split("="));
}

task("example", "Example task").setAction(example);

const config: HardhatUserConfig = {
  solidity: {
<<<<<<< HEAD
    version: "0.8.13",
=======
    version: "0.8.11",
>>>>>>> dev
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
<<<<<<< HEAD
=======
  networks: {
    goerli: {
      url: process.env.ALCHEMY_URL,
      accounts: [process.env.PRI_KEY!]
    },
    mainnet: {
      url: process.env.MAINNET_ALCHEMY_URL,
      accounts: [process.env.MAINNET_KEY!]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
>>>>>>> dev
  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
};

export default config;
