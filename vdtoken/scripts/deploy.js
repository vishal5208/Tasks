// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
	// deploy usdcToken contract
	vDToken = await ethers.deployContract("VDToken", [
		"0x949A21eedd457a9391540fAF33F5661d169de5CC",
		"0x407E8e19AC4aa2718ea84c90d499458cf05584A8",
		"0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
	]);

	await vDToken.waitForDeployment();

	console.log("Contract is deployed at : ", vDToken.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
