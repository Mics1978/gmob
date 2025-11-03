// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title GMOBPaidNFT
 * @notice ERC-721 contract where only the owner can mint NFTs, requiring payment in GMOB tokens.
 */
contract GMOBPaidNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public gmobToken;
    uint256 public mintPrice;
    uint256 private _nextTokenId;

    event MintPriceUpdated(uint256 newPrice);
    event GMOBTokenUpdated(address indexed newToken);
    event NFTMinted(address indexed payer, address indexed to, uint256 indexed tokenId, uint256 price);

    constructor() ERC721("GMOB Paid NFT", "GMOBNFT") {
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
     * @notice Mints an NFT to `to`, pulling GMOB tokens from `payer` as payment.
     * @dev Only callable by the contract owner. Requires allowance from `payer`.
     * @param to The address receiving the NFT.
     * @param payer The address providing GMOB tokens for payment.
     * @return tokenId The ID of the newly minted token.
     */
    function mint(address to, address payer) external onlyOwner returns (uint256 tokenId) {
        require(to != address(0), "GMOBPaidNFT: invalid recipient");
        require(payer != address(0), "GMOBPaidNFT: invalid payer");

        tokenId = _nextTokenId++;

        if (mintPrice > 0) {
            gmobToken.safeTransferFrom(payer, address(this), mintPrice);
        }

        _safeMint(to, tokenId);
        emit NFTMinted(payer, to, tokenId, mintPrice);
    }

    /**
     * @notice Withdraws GMOB tokens held by the contract to a specified address.
     * @param to The address receiving the withdrawn tokens.
     * @param amount The amount of GMOB tokens to withdraw.
     */
    function withdrawGMOB(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "GMOBPaidNFT: invalid recipient");
        gmobToken.safeTransfer(to, amount);
    }
}
