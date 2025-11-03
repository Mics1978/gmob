// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Optional royalties (commented for future enablement)
// import "@openzeppelin/contracts/token/common/ERC2981.sol";
// contract GMOBPaidNFT is ERC721, Ownable, ReentrancyGuard, ERC2981 { ... }
// function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner { _setDefaultRoyalty(receiver, feeNumerator); }
// function deleteDefaultRoyalty() external onlyOwner { _deleteDefaultRoyalty(); }

/**
 * @title GMOBPaidNFT
 * @notice ERC-721 contract where only the owner can mint NFTs, requiring payment in GMOB tokens.
 */
contract GMOBPaidNFT is ERC721, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    IERC20 public gmobToken;
    uint256 public mintPrice;
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    event MintPriceUpdated(uint256 newPrice);
    event GMOBTokenUpdated(address indexed newToken);
    event NFTMinted(address indexed payer, address indexed to, uint256 indexed tokenId, uint256 price);
    event BaseURIUpdated(string newBaseURI);
    event PublicMint(address indexed payer, uint256 indexed tokenId, uint256 pricePaid);
    event GMOBWithdrawn(address indexed to, uint256 amount);

    /// @notice Initializes the GMOB-paid NFT collection and sets the GMOB token address.
    constructor() ERC721("GMOB Paid NFT", "GMOBNFT") Ownable(msg.sender) {
        gmobToken = IERC20(0x12B45ABb5D8C5f7a55E04fDa17beD9ef71a9C519);
        _nextTokenId = 1;
    }

    /// @notice Sets the GMOB token address used for payments.
    /// @param newToken The new ERC-20 token address.
    function setGMOBToken(address newToken) external onlyOwner {
        require(newToken != address(0), "GMOBPaidNFT: invalid token address");
        gmobToken = IERC20(newToken);
        emit GMOBTokenUpdated(newToken);
    }

    /// @notice Updates the mint price denominated in GMOB tokens.
    /// @param newPrice The new mint price per NFT in GMOB token units.
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /// @notice Updates the base token URI used to construct token metadata URLs.
    /// @param newBaseURI The new base URI string, expected to end with a trailing slash.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /// @notice Returns the next token ID scheduled to be minted.
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /// @notice Owner-controlled mint that charges a GMOB payment from the designated payer.
    /// @dev Requires the payer to have approved this contract and cannot be re-entered.
    /// @param to Recipient address receiving the minted NFT.
    /// @param payer Address providing the GMOB payment.
    /// @return tokenId The identifier of the newly minted NFT.
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

    /// @notice Public minting flow that charges `mintPrice` GMOB tokens from the caller.
    /// @dev Caller must approve this contract to spend at least `mintPrice` GMOB tokens.
    /// @return tokenId The identifier of the newly minted NFT.
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

    /// @notice Withdraws the entire GMOB balance held by the contract to the specified address.
    /// @param to Recipient of the withdrawn GMOB tokens.
    function withdrawGMOB(address to) external onlyOwner nonReentrant {
        require(to != address(0), "GMOBPaidNFT: invalid recipient");
        uint256 balance = gmobToken.balanceOf(address(this));
        gmobToken.safeTransfer(to, balance);
        emit GMOBWithdrawn(to, balance);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}
