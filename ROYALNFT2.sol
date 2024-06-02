// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ROYALNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 private _tokenIds;

    address payable public immutable deployer;
    uint256 public immutable deployerFixedRoyalty;
    uint256 public immutable deployerPercentRoyalty;

    struct TokenSaleInfo {
        uint256 salePriceETH;
    }

    struct RoyaltyInfo {
        address payable recipient;
        uint256 fixedAmount;
        uint256 percentage;
    }

    mapping(uint256 => TokenSaleInfo) private tokenSalePrices;
    mapping(uint256 => RoyaltyInfo) private royalties;

    event Minted(uint256 tokenId, address creator, uint256 salePrice);
    event Sold(uint256 tokenId, address from, address to, uint256 salePrice);

    constructor(
        uint256 _deployerFixedRoyalty,
        uint256 _deployerPercentRoyalty
    ) ERC721("Royal NFT", "ROYALNFT") Ownable(msg.sender) {
        deployer = payable(msg.sender);
        deployerFixedRoyalty = _deployerFixedRoyalty;
        deployerPercentRoyalty = _deployerPercentRoyalty;
    }

    function mintNFTr(address recipient, string memory tokenURI, uint256 salePriceETH, uint256 _creatorFixedRoyalty, uint256 _creatorPercentRoyalty) public onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        tokenSalePrices[newItemId] = TokenSaleInfo({
            salePriceETH: salePriceETH
        });

        royalties[newItemId] = RoyaltyInfo({
            recipient: payable(recipient),
            fixedAmount: _creatorFixedRoyalty,
            percentage: _creatorPercentRoyalty
        });

        emit Minted(newItemId, recipient, salePriceETH);

        return newItemId;
    }

    function setSalePrice(uint256 tokenId, uint256 salePriceETH) public {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can set the sale price");
        tokenSalePrices[tokenId].salePriceETH = salePriceETH;
    }

    function brokerNFT(uint256 tokenId) public payable nonReentrant {
        TokenSaleInfo memory saleInfo = tokenSalePrices[tokenId];
        RoyaltyInfo memory royaltyInfo = royalties[tokenId];
        address seller = ownerOf(tokenId);
        uint256 salePrice = saleInfo.salePriceETH;

        require(msg.value == salePrice, "Incorrect sale price");

        uint256 deployerRoyalty = calculateRoyalty(salePrice, deployerFixedRoyalty, deployerPercentRoyalty);
        uint256 creatorRoyalty = calculateRoyalty(salePrice, royaltyInfo.fixedAmount, royaltyInfo.percentage);
        uint256 totalRoyaltyAmount = deployerRoyalty + creatorRoyalty;
        uint256 sellerAmount = salePrice - totalRoyaltyAmount;

        _transfer(seller, msg.sender, tokenId);

        (bool successDeployer, ) = deployer.call{value: deployerRoyalty}("");
        require(successDeployer, "Transfer to deployer failed");

        (bool successCreator, ) = royaltyInfo.recipient.call{value: creatorRoyalty}("");
        require(successCreator, "Transfer to creator failed");

        (bool successSeller, ) = payable(seller).call{value: sellerAmount}("");
        require(successSeller, "Transfer to seller failed");

        emit Sold(tokenId, seller, msg.sender, salePrice);
    }

    function calculateRoyalty(uint256 salePrice, uint256 fixedRoyalty, uint256 percentRoyalty) internal pure returns (uint256) {
        uint256 percentRoyaltyAmount = (salePrice * percentRoyalty) / 100;
        return fixedRoyalty > percentRoyaltyAmount ? fixedRoyalty : percentRoyaltyAmount;
    }
}

