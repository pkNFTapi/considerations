// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ROYALNFT.sol";

contract ROYALNFTTest is Test {
    ROYALNFT public royalNFT;
    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public creator = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public buyer = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public seller = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public buyerFromSeller = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

    function setUp() public {
        vm.startPrank(deployer);
        royalNFT = new ROYALNFT(1 ether, 10); // 1 ether fixed royalty, 10% percent royalty
        vm.stopPrank();
    }

    function testMintNFT() public {
        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.1 ether, 5); // 0.1 ether fixed royalty, 5% percent royalty
        vm.stopPrank();
        
        assertEq(royalNFT.ownerOf(tokenId), creator);
    }

    function testSetSalePrice() public {
        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.1 ether, 5); // Mint by creator
        royalNFT.setSalePrice(tokenId, 2 ether); // Set sale price by creator
        vm.stopPrank();

        // Validate that the sale price is updated using the getter function
        uint256 salePriceETH = royalNFT.getSalePrice(tokenId);
        assertEq(salePriceETH, 2 ether);
    }

    function testBrokerNFT() public {
        vm.deal(buyer, 2 ether);
        
        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.1 ether, 5); // Mint by creator
        royalNFT.setSalePrice(tokenId, 2 ether); // Set sale price by creator
        vm.stopPrank();
        
        // Buyer buys the NFT from the creator
        vm.startPrank(buyer);
        royalNFT.brokerNFT{value: 2 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), buyer);

        // Verify royalties and seller amount
        uint256 deployerRoyalty = royalNFT.calculateRoyaltyPublic(2 ether, 1 ether, 10); // Should be 1 ether (fixed > percent)
        uint256 creatorRoyalty = royalNFT.calculateRoyaltyPublic(2 ether, 0.1 ether, 5); // Should be 0.1 ether (fixed > percent)
        uint256 sellerAmount = 2 ether - deployerRoyalty - creatorRoyalty;
        
        assertEq(deployer.balance, deployerRoyalty);
        assertEq(creator.balance, creatorRoyalty);
        assertEq(buyer.balance, sellerAmount);
    }
}

