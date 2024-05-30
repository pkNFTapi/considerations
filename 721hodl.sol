// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title 721Hodl
 * @dev Implementation of a custom ERC-721 contract that can own other ERC-721 tokens.
 * The contract can receive, store, and transfer owned ERC-721 tokens.
 */
contract 721Hodl is ERC721, IERC721Receiver {

    struct OwnedNFTInfo {
        address contractAddress; // Address of the ERC-721 contract of the owned NFT
        uint256 tokenId;         // Token ID of the owned NFT
        string name;             // Name of the owned NFT
    }

    // Mapping from parent token ID to owned NFT information
    mapping(uint256 => OwnedNFTInfo) private _ownedNFTs;

    /**
     * @dev Constructor that initializes the ERC-721 token with a name and a symbol.
     * @param name The name of the ERC-721 token.
     * @param symbol The symbol of the ERC-721 token.
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev Mints a new token.
     * @param to The address to mint the token to.
     * @param tokenId The token ID to mint.
     */
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    /**
     * @dev Sets the owned NFT information for a parent token.
     * @param parentTokenId The token ID of the parent token.
     * @param nftContract The address of the ERC-721 contract of the owned NFT.
     * @param nftTokenId The token ID of the owned NFT.
     */
    function setOwnedNFT(uint256 parentTokenId, address nftContract, uint256 nftTokenId) public {
        require(ownerOf(parentTokenId) == msg.sender, "Not the owner of the token");
        IERC721Metadata nft = IERC721Metadata(nftContract);
        string memory nftName = nft.name();
        _ownedNFTs[parentTokenId] = OwnedNFTInfo(nftContract, nftTokenId, nftName);
    }

    /**
     * @dev Returns the owned NFT information for a given parent token.
     * @param tokenId The token ID of the parent token.
     * @return contractAddress The address of the owned NFT contract.
     * @return tokenId The token ID of the owned NFT.
     * @return name The name of the owned NFT.
     */
    function getOwnedNFTInfo(uint256 tokenId) public view returns (address, uint256, string memory) {
        OwnedNFTInfo memory info = _ownedNFTs[tokenId];
        return (info.contractAddress, info.tokenId, info.name);
    }

    /**
     * @dev Returns the address of the current contract.
     * @return The address of the contract.
     */
    function getContractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @dev Transfers the owned NFT to another address.
     * @param parentTokenId The token ID of the parent token.
     * @param to The address to transfer the owned NFT to.
     */
    function transferOwnedNFT(uint256 parentTokenId, address to) public {
        require(ownerOf(parentTokenId) == msg.sender, "Not the owner of the token");
        OwnedNFTInfo memory info = _ownedNFTs[parentTokenId];
        IERC721(info.contractAddress).safeTransferFrom(address(this), to, info.tokenId);
    }

    /**
     * @dev Handles the receipt of an ERC-721 token.
     * @param operator The address which called `safeTransferFrom` function.
     * @param from The address which previously owned the token.
     * @param tokenId The NFT identifier which is being transferred.
     * @param data Additional data with no specified format.
     * @return The selector of this function to confirm the token transfer.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) 
        public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

