// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NftMarketplace is ReentrancyGuard {
    using SafeMath for uint256;

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    modifier notListed(address nftAddress, uint256 tokenId, address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        require(listing.price == 0, "Already listed");
        _;
    }

    modifier isOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        require(spender == owner, "Not the owner");
        _;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        require(price > 0, "Price must be above zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) == address(this), "Not approved for marketplace");

        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        require(listedItem.price > 0, "Item not listed");
        require(msg.value == listedItem.price, "Price mismatch");

        s_proceeds[listedItem.seller] += msg.value;
        delete s_listings[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external isOwner(nftAddress, tokenId, msg.sender) {
        delete s_listings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        require(proceeds > 0, "No proceeds");

        s_proceeds[msg.sender] = 0;
        payable(msg.sender).transfer(proceeds);
    }
}
