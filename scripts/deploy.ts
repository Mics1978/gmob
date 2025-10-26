import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ethers } from "ethers";
import "dotenv/config";

async function main() {
  const name = process.env.TOKEN_NAME || "MyToken";
  const symbol = process.env.TOKEN_SYMBOL || "MTK";
  const decimals = Number(process.env.DECIMALS || "18");
  const supplyTokens = process.env.INITIAL_SUPPLY || "10000"; // 10,000 tokens
  const initialSupply = ethers.parseUnits(supplyTokens, decimals);

  const rpcUrl = process.env.BASE_SEPOLIA_URL || "https://sepolia.base.org";
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) throw new Error("PRIVATE_KEY is required");
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log("Deployer:", wallet.address);
  const bal = await provider.getBalance(wallet.address);
  console.log("Deployer balance:", ethers.formatEther(bal), "ETH");

  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const artifactPath = path.join(process.cwd(), "artifacts/contracts/MyToken.sol/MyToken.json");
  const artifactJson = JSON.parse(readFileSync(artifactPath, "utf8"));

  const factory = new ethers.ContractFactory(artifactJson.abi, artifactJson.bytecode, wallet);
  const token = await factory.deploy(name, symbol, initialSupply);
  const receipt = await token.deploymentTransaction()?.wait();
  const address = await token.getAddress();
  console.log("Token deployed at:", address);
  console.log(`Name: ${name}, Symbol: ${symbol}, Decimals: ${decimals}, Initial supply: ${supplyTokens}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
