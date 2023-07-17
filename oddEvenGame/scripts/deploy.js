const hre = require("hardhat");
const networkConfig = require("../helper");

async function main() {
	const mumbaiData = networkConfig.networkConfig[80001];

	const oddEvenGame = await ethers.deployContract("OddEvenGame", [
		mumbaiData.vrfCoordinatorV2,
		mumbaiData.entranceFee,
		mumbaiData.gasLane,
		mumbaiData.subscriptionId,
		mumbaiData.callbackGasLimit,
		mumbaiData.interval,
	]);

	await oddEvenGame.waitForDeployment();

	console.log("contract is deployed at : ", oddEvenGame.target);
	// 0x4CD402132aD32a5fE83341fE18fc9FA9b9dDa46A
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
