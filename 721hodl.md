# explanation of 721hodl.sol

Internal Documentation Breakdown:

    Contract Declaration and Imports:
        Importing ERC721, IERC721Receiver, and IERC721Metadata from OpenZeppelin to use ERC-721 functionalities and handle receipt of ERC-721 tokens.

    Struct Definition:
        OwnedNFTInfo: Holds the contract address, token ID, and name of the owned NFT.

    State Variable:
        _ownedNFTs: Mapping from parent token ID to OwnedNFTInfo.

    Constructor:
        Initializes the ERC-721 token with a name and a symbol.

    Mint Function:
        Allows minting of a new token to a specified address.

    setOwnedNFT Function:
        Sets the information of an owned NFT for a parent token.

    getOwnedNFTInfo Function:
        Returns the contract address, token ID, and name of the owned NFT for a given parent token.

    getContractAddress Function:
        Returns the address of the contract itself.

    transferOwnedNFT Function:
        Transfers the owned NFT from the contract to another address.

    onERC721Received Function:
        Handles the receipt of an ERC-721 token, returning the function selector to confirm the token transfer.
