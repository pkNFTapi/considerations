// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IFilecoinAPI {
    function storeData(bytes calldata data) external returns (string memory cid);
    function retrieveData(string memory cid) external view returns (bytes memory);
}

contract NFroyalT is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public immutable creator;
    uint256 public immutable creatorFixedRoyalty;
    uint256 public immutable creatorRoyaltyPercentage;
    IFilecoinAPI public filecoinAPI;

    struct TokenSaleInfo {
        uint256 salePriceETH;
    }

    struct RoyaltyInfo {
        address payable recipient;
        uint256 percentage;
        uint256 fixedAmount;
    }

    mapping(uint256 => TokenSaleInfo) private tokenSalePrices;
    mapping(uint256 => RoyaltyInfo[]) private royalties;
    mapping(uint256 => string) public tokenDataCIDs; // Mapping token IDs to their data CIDs

    event RoyaltyPaid(address indexed recipient, uint256 amount);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId, uint256 salePrice);
    event DataStored(uint256 indexed tokenId, string cid);
    event SalePriceSetETH(uint256 indexed tokenId, uint256 salePrice);

    constructor(
        address payable _creator,
        uint256 _creatorFixedRoyaltyInEther,
        uint256 _creatorRoyaltyPercentage,
        address _filecoinAPI
    ) ERC721("MarketplaceRoyalty", "NFTMR") Ownable(_creator) {
        require(_creator != address(0), "Invalid creator address");
        require(_creatorRoyaltyPercentage >= 0 && _creatorRoyaltyPercentage <= 100, "Invalid royalty percentage");

        creator = _creator;
        creatorFixedRoyalty = _creatorFixedRoyaltyInEther * 1 ether; // Correct conversion to wei
        creatorRoyaltyPercentage = _creatorRoyaltyPercentage;
        filecoinAPI = IFilecoinAPI(_filecoinAPI);
    }

    function mintNFT(address to, string memory tokenURI, bytes calldata data) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        string memory cid = filecoinAPI.storeData(data);
        tokenDataCIDs[newItemId] = cid;
        emit DataStored(newItemId, cid);

        return newItemId;
    }

    function setSalePriceETH(uint256 tokenId, uint256 salePrice) external onlyOwner {
        tokenSalePrices[tokenId] = TokenSaleInfo({ salePriceETH: salePrice });
        emit SalePriceSetETH(tokenId, salePrice);
    }

    function brokerTransferETH(
        address from,
        address to,
        uint256 tokenId
    ) public payable nonReentrant {
        uint256 salePrice = tokenSalePrices[tokenId].salePriceETH;
        require(msg.value >= salePrice, "Insufficient payment");
        require(ownerOf(tokenId) == from, "Transfer not authorized by owner");

        RoyaltyInfo[] memory royaltyInfo = royalties[tokenId];
        uint256 totalRoyaltyAmount = 0;

        for (uint256 i = 0; i < royaltyInfo.length; i++) {
            uint256 recipientRoyaltyAmount = (salePrice * royaltyInfo[i].percentage) / 100;
            if (recipientRoyaltyAmount < royaltyInfo[i].fixedAmount) {
                recipientRoyaltyAmount = royaltyInfo[i].fixedAmount;
            }
            if (totalRoyaltyAmount + recipientRoyaltyAmount > salePrice) {
                recipientRoyaltyAmount = salePrice - totalRoyaltyAmount;
            }
            totalRoyaltyAmount += recipientRoyaltyAmount;

            (bool success, ) = royaltyInfo[i].recipient.call{value: recipientRoyaltyAmount}("");
            require(success, "Royalty transfer failed");
            emit RoyaltyPaid(royaltyInfo[i].recipient, recipientRoyaltyAmount);

            if (totalRoyaltyAmount >= salePrice) {
                break;
            }
        }

        uint256 sellerAmount = salePrice - totalRoyaltyAmount;
        (bool successSeller, ) = from.call{value: sellerAmount}("");
        require(successSeller, "Transfer to seller failed");

        _transfer(from, to, tokenId);
        emit NFTTransferred(from, to, tokenId, salePrice);

        royalties[tokenId].push(RoyaltyInfo({
            recipient: payable(to),
            percentage: 0,
            fixedAmount: 0
        }));
    }

    function retrieveTokenData(uint256 tokenId) external view returns (bytes memory) {
        string memory cid = tokenDataCIDs[tokenId];
        return filecoinAPI.retrieveData(cid);
    }
}
