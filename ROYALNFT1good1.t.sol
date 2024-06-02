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
        royalNFT = new ROYALNFT(0.001 ether, 5); // 0.001 ether fixed royalty, 5% percentage royalty
        vm.stopPrank();
    }

    function logBalances(string memory label) internal view {
        console.log(label);
        console.log("Deployer Balance:", toEther(address(deployer).balance));
        console.log("Creator Balance:", toEther(address(creator).balance));
        console.log("Buyer Balance:", toEther(address(buyer).balance));
        console.log("Second Buyer Balance:", toEther(address(secondBuyer).balance));
    }

    function toEther(uint256 amount) internal pure returns (string memory) {
        uint256 etherValue = amount / 1 ether;
        uint256 decimalValue = amount % 1 ether;
        return string(abi.encodePacked(
            uintToStr(etherValue), ".",
            uintToStr(decimalValue / 10**17), // 1 gwei
            uintToStr((decimalValue / 10**14) % 10**3), // 1 szabo
            uintToStr((decimalValue / 10**11) % 10**3), // 1 finney
            uintToStr((decimalValue / 10**8) % 10**3), // 1 micro
            uintToStr((decimalValue / 10**5) % 10**3), // 1 nano
            uintToStr((decimalValue / 10**2) % 10**3), // 1 pico
            uintToStr(decimalValue % 10**2) // remaining
        ));
    }

    function uintToStr(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function testMintNFT() public {
        logBalances("Initial Balances:");

        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.2 ether, 25); // Mint by creator with 0.2 ether fixed royalty and 25% percentage royalty
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), creator);

        logBalances("Balances after Mint:");
    }

    function testSetSalePrice() public {
        logBalances("Initial Balances:");

        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.2 ether, 25); // Mint by creator
        royalNFT.setSalePrice(tokenId, 1 ether); // Set sale price by creator
        vm.stopPrank();

        // Validate that the sale price is updated using the getter function
        uint256 salePriceETH = royalNFT.getSalePrice(tokenId);
        assertEq(salePriceETH, 1 ether);

        logBalances("Balances after Set Sale Price:");
    }

    function testBrokerNFT() public {
        logBalances("Initial Balances:");

        vm.deal(buyer, 2 ether);

        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.2 ether, 25); // Mint by creator
        royalNFT.setSalePrice(tokenId, 1 ether); // Set sale price by creator
        vm.stopPrank();

        // Buyer buys the NFT from the creator
        vm.startPrank(buyer);
        royalNFT.brokerNFT{value: 1 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), buyer);

        // Verify royalties and seller amount
        uint256 deployerRoyalty = royalNFT.calculateRoyaltyPublic(1 ether, 0.001 ether, 5); // Should be 0.05 ether (percentage > fixed)
        uint256 creatorRoyalty = royalNFT.calculateRoyaltyPublic(1 ether, 0.2 ether, 25); // Should be 0.25 ether (percentage > fixed)
        uint256 sellerAmount = 1 ether - deployerRoyalty - creatorRoyalty;

        console.log("First Transfer:");
        console.log("Deployer Royalty:", toEther(deployerRoyalty));
        console.log("Creator Royalty:", toEther(creatorRoyalty));
        console.log("Seller Amount:", toEther(sellerAmount));

        logBalances("Balances after First Transfer:");
    }

    function testMultipleTransfers() public {
        logBalances("Initial Balances:");

        vm.deal(buyer, 2 ether);
        vm.deal(secondBuyer, 3 ether);

        vm.startPrank(creator);
        uint256 tokenId = royalNFT.mintNFTr("https://token-uri.com", 1 ether, 0.2 ether, 25); // Mint by creator
        royalNFT.setSalePrice(tokenId, 1 ether); // Set sale price by creator
        vm.stopPrank();

        // First buyer buys the NFT from the creator
        vm.startPrank(buyer);
        royalNFT.brokerNFT{value: 1 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), buyer);

        // Verify royalties and seller amount for first transfer
        uint256 deployerRoyalty1 = royalNFT.calculateRoyaltyPublic(1 ether, 0.001 ether, 5); // Should be 0.05 ether
        uint256 creatorRoyalty1 = royalNFT.calculateRoyaltyPublic(1 ether, 0.2 ether, 25); // Should be 0.25 ether
        uint256 sellerAmount1 = 1 ether - deployerRoyalty1 - creatorRoyalty1;

        console.log("First Transfer:");
        console.log("Deployer Royalty:", toEther(deployerRoyalty1));
        console.log("Creator Royalty:", toEther(creatorRoyalty1));
        console.log("Seller Amount:", toEther(sellerAmount1));

        logBalances("Balances after First Transfer:");

        // Set new sale price by the first buyer
        vm.startPrank(buyer);
        royalNFT.setSalePrice(tokenId, 2 ether);
        vm.stopPrank();

        // Second buyer buys the NFT from the first buyer
        vm.startPrank(secondBuyer);
        royalNFT.brokerNFT{value: 2 ether}(tokenId);
        vm.stopPrank();

        assertEq(royalNFT.ownerOf(tokenId), secondBuyer);

        // Verify royalties and seller amount for second transfer
        uint256 deployerRoyalty2 = royalNFT.calculateRoyaltyPublic(2 ether, 0.001 ether, 5); // Should be 0.1 ether
        uint256 creatorRoyalty2 = royalNFT.calculateRoyaltyPublic(2 ether, 0.2 ether, 25); // Should be 0.5 ether (percentage > fixed)
        uint256 sellerAmount2 = 2 ether - deployerRoyalty2 - creatorRoyalty2;

        console.log("Second Transfer:");
        console.log("Deployer Royalty:", toEther(deployerRoyalty2));
        console.log("Creator Royalty:", toEther(creatorRoyalty2));
        console.log("Seller Amount:", toEther(sellerAmount2));

        logBalances("Balances after Second Transfer:");
    }
}
