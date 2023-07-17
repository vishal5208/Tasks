const hre = require("hardhat");
const networkConfig = require("../helper");
const mumbaiData = networkConfig.networkConfig[80001];

async function verifyContracts(contractInfo) {
	for (const info of contractInfo) {
		await hre.run("verify:verify", {
			address: info.address,
			constructorArguments: info.args || [],
		});
	}
}

const contractsToVerify = [
	{
		address: "0x4CD402132aD32a5fE83341fE18fc9FA9b9dDa46A",
		args: [
			mumbaiData.vrfCoordinatorV2,
			mumbaiData.entranceFee,
			mumbaiData.gasLane,
			mumbaiData.subscriptionId,
			mumbaiData.callbackGasLimit,
			mumbaiData.interval,
		],
	},
];

verifyContracts(contractsToVerify);
