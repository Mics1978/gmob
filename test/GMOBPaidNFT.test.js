const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GMOBPaidNFT", function () {
  it("supports owner minting and public minting with GMOB payments", async function () {
    const [owner, alice] = await ethers.getSigners();

    const MockGMOB = await ethers.getContractFactory("MockGMOB");
    const mockGMOB = await MockGMOB.deploy();
    await mockGMOB.waitForDeployment();

    const GMOBPaidNFT = await ethers.getContractFactory("GMOBPaidNFT");
    const nft = await GMOBPaidNFT.deploy();
    await nft.waitForDeployment();

    const mockGMOBAddress = await mockGMOB.getAddress();
    const nftAddress = await nft.getAddress();

    await nft.setGMOBToken(mockGMOBAddress);
    const mintPrice = ethers.parseEther("5");
    await nft.setMintPrice(mintPrice);
    await nft.setBaseURI("https://metadata.gmob.example/");

    await mockGMOB.mint(alice.address, ethers.parseEther("100"));
    await mockGMOB.connect(alice).approve(nftAddress, ethers.parseEther("100"));

    // Owner-triggered mint to Alice with Alice providing payment.
    await expect(nft.mint(alice.address, alice.address))
      .to.emit(nft, "NFTMinted")
      .withArgs(alice.address, alice.address, 1n, mintPrice);

    expect(await nft.ownerOf(1)).to.equal(alice.address);
    expect(await nft.tokenURI(1)).to.equal("https://metadata.gmob.example/1");

    // Public mint by Alice paying mintPrice GMOB directly.
    await expect(nft.connect(alice).publicMint())
      .to.emit(nft, "PublicMint")
      .withArgs(alice.address, 2n, mintPrice);

    expect(await nft.ownerOf(2)).to.equal(alice.address);
  });
});
