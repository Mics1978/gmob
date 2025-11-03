// scripts/deploy.js
// Deploys the GMOBPaidNFT contract to Base or Base Sepolia using Hardhat.

require("dotenv").config();

const fs = require("fs");
const path = require("path");
const { ethers, artifacts, network } = require("hardhat");

const NETWORK_RPC_ENV = {
  base: "BASE_RPC_URL",
  baseSepolia: "BASE_SEPOLIA_RPC_URL",
};

async function main() {
  if (!process.env.PRIVATE_KEY) {
    throw new Error("PRIVATE_KEY is not set in the environment. Check your .env file.");
  }

  const rpcEnvKey = NETWORK_RPC_ENV[network.name];
  if (rpcEnvKey && !process.env[rpcEnvKey]) {
    throw new Error(`${rpcEnvKey} is not set in the environment. Check your .env file.`);
  }

  const [deployer] = await ethers.getSigners();

  console.log("\n🚀 Deploying GMOBPaidNFT");
  console.log(`Network: ${network.name} (chainId: ${network.config.chainId ?? "unknown"})`);
  console.log(`RPC Source: ${rpcEnvKey ? rpcEnvKey : "default hardhat config"}`);
  console.log(`Deployer wallet: ${deployer.address}`);

  const factory = await ethers.getContractFactory("GMOBPaidNFT");
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const deploymentTx = contract.deploymentTransaction();
  const receipt = await deploymentTx.wait();
  const contractAddress = await contract.getAddress();

  console.log("\n✅ Deployment complete");
  console.log(`Contract address: ${contractAddress}`);
  console.log(`Gas used: ${receipt.gasUsed.toString()}`);

  const abi = (await artifacts.readArtifact("GMOBPaidNFT")).abi;
  const abiOutputPath = path.resolve(__dirname, "../artifacts/GMOBPaidNFT_ABI.json");
  fs.writeFileSync(abiOutputPath, JSON.stringify(abi, null, 2));
  console.log(`ABI saved to: ${abiOutputPath}`);

  console.log("\n📋 Follow-up calls (example):");
  console.log("- await contract.setMintPrice(ethers.parseUnits('1', 18));");
  console.log("- await contract.setBaseURI('https://metadata.example/api/');");
  console.log("- await contract.setGMOBToken('0x12B45ABb5D8C5f7a55E04fDa17beD9ef71a9C519');");
  console.log("\nRemember to configure allowances for public minting if required.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
  });
