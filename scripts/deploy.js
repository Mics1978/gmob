// scripts/deploy.js
// Deploys the GMOBPaidNFT contract to Base or Base Sepolia using Hardhat.

require("dotenv").config();

const { ethers, network } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("\n🚀 Deploying GMOBPaidNFT");
  console.log(`Network: ${network.name} (chainId: ${network.config.chainId ?? "unknown"})`);
  console.log(`Deployer: ${deployer.address}`);

  const defaultGmobToken = "0x12B45ABb5D8C5f7a55E04fDa17beD9ef71a9C519";
  const configuredToken = process.env.GMOB_TOKEN_ADDRESS || defaultGmobToken;
  console.log(`Configured GMOB token: ${configuredToken}`);

  const factory = await ethers.getContractFactory("GMOBPaidNFT");
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log(`\n✅ GMOBPaidNFT deployed at: ${address}`);
  console.log("Use setGMOBToken if you need to update the payment token address after deployment.");
  console.log("Remember to set mint price, base URI, and optionally enable public minting allowances.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
