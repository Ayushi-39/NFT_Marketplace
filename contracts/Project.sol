// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Project
 * @dev A simple NFT Marketplace contract.
 */
contract Project {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // The address of the NFT contract
    address public nftContractAddress;

    // A struct to represent a listed token
    struct ListedToken {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    // A mapping from tokenId to the ListedToken struct
    mapping(uint256 => ListedToken) public listedTokens;

    // Event to be emitted when a token is listed
    event TokenListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );

    // Event to be emitted when a token is sold
    event TokenSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    /**
     * @dev Sets the address of the NFT contract.
     * @param _nftContractAddress The address of the NFT contract.
     */
    constructor(address _nftContractAddress) {
        nftContractAddress = _nftContractAddress;
    }

    /**
     * @dev Core function to list an NFT for sale.
     * @param tokenId The ID of the token to be listed.
     * @param price The price of the token in wei.
     */
    function listToken(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than zero");
        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner of this token");

        listedTokens[tokenId] = ListedToken({
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            currentlyListed: true
        });

        emit TokenListed(tokenId, msg.sender, price);
    }

    /**
     * @dev Core function to purchase a listed NFT.
     * @param tokenId The ID of the token to be purchased.
     */
    function purchaseToken(uint256 tokenId) public payable {
        ListedToken storage listedToken = listedTokens[tokenId];
        require(listedToken.currentlyListed, "Token not listed for sale");
        require(msg.value >= listedToken.price, "Insufficient payment");

        listedToken.currentlyListed = false;

        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransferFrom(listedToken.seller, msg.sender, tokenId);

        listedToken.seller.transfer(msg.value);

        emit TokenSold(tokenId, listedToken.seller, msg.sender, msg.value);
    }
}
