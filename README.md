# <h1 align="center"> Replant BeaNFTs </h1>
### About 

On April 17th, 2022, Beanstalk was hacked for over 70 million dollars, taking all the liquidity due to a governance exploit. To restart, Beanstalk Farm introduced the Barnraise, a recapitlization measure of stolen assets.Those who have contirbuted over 1000 USDC in the Beanstalk Barnraise are eligble to mint a BeaNFT. Size of purchase, and having prior beaNFTs impacts the rarity of the NFT given. 
### Getting Started

 * Install Foundry: 
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup

```

* Install foundry and Hardhat;
```bash
    cd BeaNFT
    forge install
    npm install
```

 * Run tests:
```bash
forge test

forge snapshot
```

### Optimizations
As with all contracts, minimizing gas is a priority for developers. Beanstalk uses a merkle tree to determine whether a user is eglible for a mint, in a gas efficent method. Futher gas optimizations were made on Openzeppelins ERC721Enumerable.sol. The gas savings, especially on bulk mints, can be seen here: 
### Notes

Many Optimizations where taken in order to ensure low gas fees. As such, this is not a generic contract to be forked (without modifications).
This uses a Merkle tree in order to verify egliblity, the example can be seen in `merkle_stuff/index.js` 
A downside is that ownerOf() and balanceOf() take considerably more gas. This was accepted as allowed us to reduce the gas costs of mints and transfers.
