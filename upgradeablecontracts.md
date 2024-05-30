# Steps to Create and Deploy Upgradeable Contracts

    Install the upgradeable contracts package from OpenZeppelin:
```bash
    npm install @openzeppelin/contracts-upgradeable
```
When writing an upgradeable contract, replace constructors with initializer functions. 
# example upgradeable ERC-721 contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyUpgradeableNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    function initialize(address owner) initializer public {
        __ERC721_init("MyUpgradeableNFT", "NFT");
        __Ownable_init(owner);
    }
}
```




<a href="https://docs.openzeppelin.com/learn/upgrading-smart-contracts">upgrading smart contracts</a><br />
<a href="https://docs.openzeppelin.com/contracts/5.x/upgradeable">npm install @openzeppelin/contracts-upgradeable @openzeppelin/contracts</a><br />
<a href="https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol">OwnableUpgradeable.sol</a><br />
<a href="https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/AccessControlUpgradeable.sol">AccessControlUpgradeable.sol</a><br />


