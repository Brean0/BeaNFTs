require("@nomicfoundation/hardhat-toolbox");
//require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.10",
  networks: {
    rinkeby:{
        url:'https://eth-rinkeby.alchemyapi.io/v2/${process.env.RINKEBY_KEY',
        accounts: ['process.env.PRI_KEY'],
    }, 
  },
  etherscan: {
    apiKey: 'process.env.API_KEY',
  },
};
