// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ROYALNFT.sol";

contract ROYALNFTTest is Test {
    ROYALNFT public royalNFT;
    address public deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public creator = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public buyer = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public secondBuyer = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

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
        
        console.log("Deployer Royalty:", deployerRoyalty); // Should be 1 ether
        console.log("Creator Royalty:", creatorRoyalty); // Should be 0.1 ether
        console.log("Seller Amount:", sellerAmount); // Should be 0.9 ether
        
        console.log("Deployer Balance:", deployer.balance); 
        console.log("Creator Balance:", creator.balance); 
        console.log("Buyer Balance:", buyer.balance);

        // Since the creator is also the initial seller, they should receive both the royalty and the remaining sale amount
        assertEq(deployer.balance, 1 ether);
        assertEq(creator.balance, 1 ether); // Creator receives 0.1 ether royalty and 0.9 ether sale amount
        assertEq(buyer.balance, 0);
    }

    function testMultipleTransfers() public {
        vm.deal(buyer, 2 ether);
        vm.deal(secondBuyer, 3 ether);

        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.1 ether, 5); // Mint by creator
        royalNFT.setSalePrice(tokenId, 2 ether); // Set sale price by creator
        vm.stopPrank();

        // First buyer buys the NFT from the creator
        vm.startPrank(buyer);
        royalNFT.brokerNFT{value: 2 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), buyer);

        // Verify royalties and seller amount for first transfer
        uint256 deployerRoyalty1 = royalNFT.calculateRoyaltyPublic(2 ether, 1 ether, 10); // Should be 1 ether
        uint256 creatorRoyalty1 = royalNFT.calculateRoyaltyPublic(2 ether, 0.1 ether, 5); // Should be 0.1 ether
        uint256 sellerAmount1 = 2 ether - deployerRoyalty1 - creatorRoyalty1;

        console.log("First Transfer:");
        console.log("Deployer Royalty:", deployerRoyalty1); // Should be 1 ether
        console.log("Creator Royalty:", creatorRoyalty1); // Should be 0.1 ether
        console.log("Seller Amount:", sellerAmount1); // Should be 0.9 ether

        assertEq(deployer.balance, 1 ether);
        assertEq(creator.balance, 1 ether); // Creator receives 0.1 ether royalty and 0.9 ether sale amount
        assertEq(buyer.balance, 0);

        // Set new sale price by the first buyer
        vm.startPrank(buyer);
        royalNFT.setSalePrice(tokenId, 3 ether);
        vm.stopPrank();

        // Second buyer buys the NFT from the first buyer
        vm.startPrank(secondBuyer);
        royalNFT.brokerNFT{value: 3 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), secondBuyer);

        // Verify royalties and seller amount for second transfer
        uint256 deployerRoyalty2 = royalNFT.calculateRoyaltyPublic(3 ether, 1 ether, 10); // Should be 1 ether
        uint256 creatorRoyalty2 = royalNFT.calculateRoyaltyPublic(3 ether, 0.1 ether, 5); // Should be 0.15 ether (greater than fixed)
        uint256 sellerAmount2 = 3 ether - deployerRoyalty2 - creatorRoyalty2;

        console.log("Second Transfer:");
        console.log("Deployer Royalty:", deployerRoyalty2); // Should be 1 ether
        console.log("Creator Royalty:", creatorRoyalty2); // Should be 0.15 ether
        console.log("Seller Amount:", sellerAmount2); // Should be 1.85 ether

        assertEq(deployer.balance, 2 ether); // Accumulated from both sales
        assertEq(creator.balance, 1.15 ether); // 1 ether from first sale + 0.15 ether from second sale
        assertEq(buyer.balance, 1.85 ether); // Buyer receives the remaining amount from the second sale
    }
}

