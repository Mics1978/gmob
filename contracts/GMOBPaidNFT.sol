// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title GMOBPaidNFT
 * @notice ERC-721 contract where only the owner can mint NFTs, requiring payment in GMOB tokens.
 */
contract GMOBPaidNFT is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public gmobToken;
    uint256 public mintPrice;
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    event MintPriceUpdated(uint256 newPrice);
    event GMOBTokenUpdated(address indexed newToken);
    event NFTMinted(address indexed payer, address indexed to, uint256 indexed tokenId, uint256 price);
    event BaseURIUpdated(string newBaseURI);
    event PublicMint(address indexed payer, uint256 indexed tokenId, uint256 pricePaid);

    constructor() ERC721("GMOB Paid NFT", "GMOBNFT") Ownable(msg.sender) {
        gmobToken = IERC20(0x12B45ABb5D8C5f7a55E04fDa17beD9ef71a9C519);
        _nextTokenId = 1;
    }

    /**
     * @notice Sets the GMOB token address used for payments.
     * @param newToken The new ERC-20 token address.
     */
    function setGMOBToken(address newToken) external onlyOwner {
        require(newToken != address(0), "GMOBPaidNFT: invalid token address");
        gmobToken = IERC20(newToken);
        emit GMOBTokenUpdated(newToken);
    }

    /**
     * @notice Updates the mint price denominated in GMOB tokens.
     * @param newPrice The new mint price.
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /**
     * @notice Updates the base token URI used by tokenURI.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Returns the next token ID that will be minted.
     */
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @notice Mints an NFT to `to`, pulling GMOB tokens from `payer` as payment.
     * @dev Only callable by the contract owner. Requires allowance from `payer`.
     * @param to The address receiving the NFT.
     * @param payer The address providing GMOB tokens for payment.
     * @return tokenId The ID of the newly minted token.
     */
    function mint(address to, address payer) external onlyOwner nonReentrant returns (uint256 tokenId) {
        require(to != address(0), "GMOBPaidNFT: invalid recipient");
        require(payer != address(0), "GMOBPaidNFT: invalid payer");

        tokenId = _nextTokenId;
        unchecked {
            ++_nextTokenId;
        }

        uint256 price = mintPrice;
        if (price > 0) {
            gmobToken.safeTransferFrom(payer, address(this), price);
        }

        _safeMint(to, tokenId);
        emit NFTMinted(payer, to, tokenId, price);
    }

    /**
     * @notice Allows the public to mint an NFT by paying the mint price in GMOB tokens.
     * @dev Requires the sender to approve this contract for `mintPrice` GMOB tokens prior to calling.
     * @return tokenId The ID of the newly minted token.
     */
    function publicMint() external nonReentrant returns (uint256 tokenId) {
        uint256 price = mintPrice;
        require(price > 0, "GMOBPaidNFT: mint price not set");

        tokenId = _nextTokenId;
        unchecked {
            ++_nextTokenId;
        }

        gmobToken.safeTransferFrom(msg.sender, address(this), price);

        _safeMint(msg.sender, tokenId);
        emit PublicMint(msg.sender, tokenId, price);
    }

    /**
     * @notice Withdraws GMOB tokens held by the contract to a specified address.
     * @param to The address receiving the withdrawn tokens.
     */
    function withdrawGMOB(address to) external onlyOwner {
        require(to != address(0), "GMOBPaidNFT: invalid recipient");
        uint256 balance = gmobToken.balanceOf(address(this));
        gmobToken.safeTransfer(to, balance);
    }

    /**
     * @dev Returns the base URI for computing {tokenURI}. Empty by default.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
