The NFroyalT contract is an ERC721 token contract that incorporates a royalty mechanism. This mechanism ensures that the original creator of the token receives a royalty payment upon the sale of any token. The royalty can be either a fixed amount or a percentage of the sale price, providing flexibility in how royalties are managed.
Contract Components

    Pragma Directive
    
   ```bash
    pragma solidity ^0.8.20;
    ```
    
    Specifies the Solidity compiler version used for the contract, ensuring compatibility with Solidity version 0.8.20 and above

    Imports
    ```bash
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    ```
ERC721URIStorage: Extension of ERC721 for managing token URIs
Ownable: Provides basic access control mechanisms
Strings: Library for string operations
ReentrancyGuard: Protection against reentrancy attacks

state varialbes:
```bash
uint256 public tokenCounter;
address payable public immutable creator;
uint256 public immutable fixedRoyalty;
uint256 public royaltyPercentage;
```
Events
```bash
event RoyaltyPaid(address indexed recipient, uint256 amount);
event NFTTransferred(address indexed from, address indexed to, uint256 tokenId, uint256 salePrice);
```
RoyaltyPaid: Emitted when a royalty payment is made
NFTTransferred: Emitted when a token is transferred

constructor:

```bash
constructor(
    address payable _creator,
    uint256 _fixedRoyalty,
    uint256 _royaltyPercentage,
    address initialOwner
) ERC721("NFroyalT", "NFTR") Ownable(initialOwner) {
```

The constructor initializes the contract with the creator's address, fixed royalty amount, royalty percentage, and initial owner.

    _creator: Address of the royalty recipient
    _fixedRoyalty: Fixed royalty amount
    _royaltyPercentage: Percentage of the sale price to be paid as royalty
    initialOwner: Initial owner of the contract

createNFTR Function
```bash
function createNFTR(string memory _tokenURI) public onlyOwner returns (uint256) {
```
Allows the contract owner to create a new NFT.

    _tokenURI: URI for the token metadata
    Returns the ID of the newly created token

    brokerTransfer Function

    ```bash
    function brokerTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 salePrice
) public payable nonReentrant {
```
Handles the transfer of a token with a royalty payment.

    from: Current owner of the token.
    to: New owner of the token.
    tokenId: ID of the token being transferred.
    salePrice: Sale price of the token.
    Ensures the payment is sufficient and authorized by the token owner.
    Calculates and transfers the royalty to the creator.
    Transfers the remaining amount to the seller.
    Emits RoyaltyPaid and NFTTransferred events.

setRoyaltyPercentage Function






    
