// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing necessary OpenZeppelin contracts for ERC721, ownership, string operations, and reentrancy protection.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFroyalT
 * @dev NFroyalT is a contract for managing ERC721 tokens with a royalty system.
 * The contract allows the creation of NFTs and manages royalty payments to a designated creator
 * during the transfer of tokens. The royalty can be either a fixed amount or a percentage of the sale price.
 */
contract NFroyalT is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256; // Use Strings library for uint256 type.

    uint256 public tokenCounter; // Counter to keep track of token IDs.
    address payable public immutable creator; // Address of the creator to receive royalties.
    uint256 public immutable fixedRoyalty; // Fixed royalty amount to be paid.
    uint256 public royaltyPercentage; // Percentage of the sale price to be paid as royalty.

    // Events to log royalty payments and NFT transfers.
    event RoyaltyPaid(address indexed recipient, uint256 amount);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId, uint256 salePrice);

    /**
     * @dev Constructor to initialize the NFroyalT contract.
     * @param _creator Address of the creator to receive royalties.
     * @param _fixedRoyalty Fixed royalty amount to be paid.
     * @param _royaltyPercentage Percentage of the sale price to be paid as royalty.
     * @param initialOwner Initial owner of the contract.
     */
    constructor(
        address payable _creator,
        uint256 _fixedRoyalty,
        uint256 _royaltyPercentage,
        address initialOwner
    ) ERC721("NFroyalT", "NFTR") Ownable(initialOwner) {
        require(_creator != address(0), "Invalid creator address");
        require(_fixedRoyalty >= 0, "Fixed royalty must be non-negative");
        require(_royaltyPercentage >= 0 && _royaltyPercentage <= 100, "Invalid royalty percentage");

        tokenCounter = 0; // Initialize the token counter.
        creator = _creator; // Set the creator address.
        fixedRoyalty = _fixedRoyalty; // Set the fixed royalty amount.
        royaltyPercentage = _royaltyPercentage; // Set the royalty percentage.
    }

    /**
     * @dev Function to create a new NFT.
     * @param _tokenURI URI of the token metadata.
     * @return uint256 ID of the newly created token.
     */
    function createNFTR(string memory _tokenURI) public onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter; // Get the current token ID.
        _safeMint(msg.sender, newItemId); // Mint the new token.
        _setTokenURI(newItemId, _tokenURI); // Set the token URI.
        tokenCounter++; // Increment the token counter.
        return newItemId; // Return the new token ID.
    }

    /**
     * @dev Function to transfer an NFT with royalty payment.
     * @param from Address of the current token owner.
     * @param to Address of the recipient.
     * @param tokenId ID of the token to be transferred.
     * @param salePrice Sale price of the token.
     */
    function brokerTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 salePrice
    ) public payable nonReentrant {
        require(msg.value >= salePrice, "Insufficient payment"); // Ensure the payment is sufficient.
        require(ownerOf(tokenId) == from, "Transfer not authorized by owner"); // Ensure the transfer is authorized.

        uint256 royaltyAmount = (salePrice * royaltyPercentage) / 100; // Calculate the royalty amount.
        if (royaltyAmount < fixedRoyalty) {
            royaltyAmount = fixedRoyalty; // Ensure the royalty amount is at least the fixed royalty.
        }
        require(royaltyAmount <= salePrice, "Royalty exceeds sale price"); // Ensure the royalty does not exceed the sale price.

        if (royaltyAmount > 0) {
            (bool successRoyalty, ) = creator.call{value: royaltyAmount}(""); // Transfer the royalty to the creator.
            require(successRoyalty, "Royalty transfer failed"); // Ensure the royalty transfer succeeded.
            emit RoyaltyPaid(creator, royaltyAmount); // Emit an event for the royalty payment.
        }

        uint256 sellerAmount = salePrice - royaltyAmount; // Calculate the amount to be transferred to the seller.
        (bool successSeller, ) = from.call{value: sellerAmount}(""); // Transfer the remaining amount to the seller.
        require(successSeller, "Transfer to seller failed"); // Ensure the transfer to the seller succeeded.

        _transfer(from, to, tokenId); // Transfer the token.
        emit NFTTransferred(from, to, tokenId, salePrice); // Emit an event for the token transfer.
    }

    /**
     * @dev Function to set the royalty percentage.
     * @param _royaltyPercentage New royalty percentage.
     */
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage >= 0 && _royaltyPercentage <= 100, "Invalid royalty percentage");
        royaltyPercentage = _royaltyPercentage; // Set the new royalty percentage.
    }

    /**
     * @dev Function to get the token URI.
     * @param tokenId ID of the token.
     * @return string URI of the token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token is owned.
        string memory baseURI = _baseURI(); // Get the base URI.
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : ""; // Return the complete URI.
    }

    /**
     * @dev Fallback function to receive Ether when msg.data is empty.
     */
    receive() external payable {
        // Function to receive Ether. msg.data must be empty.
    }

    /**
     * @dev Fallback function to receive Ether when msg.data is not empty.
     */
    fallback() external payable {
        // Function to receive Ether. msg.data is not empty.
    }
}

