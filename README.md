# <h1 align="center"> Replant BeaNFTs </h1>

**ERC721 contract Optimized for Genesis BeaNFTs**

![Github Actions](https://github.com/devanonon/hardhat-foundry-template/workflows/test/badge.svg)

### Getting Started

 * Use Foundry: 
```bash
forge install
forge test
```

 * Use Hardhat:
```bash
npm install
npx hardhat test
```


 * Run tests:
```bash
forge test

forge snapshot
```

### Notes

Many Optimizations where taken in order to ensure low gas fees. 
A downside is that ownerOf() and balanceOf() take considerably more gas. This was accepted as allowed us to reduce the gas costs of mints and transfers.
