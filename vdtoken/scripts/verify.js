const hre = require("hardhat");

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
		address: "0x4D825a7b08e55081d28e97483e334C9827dB6fc5",
		args: [
			"0x949A21eedd457a9391540fAF33F5661d169de5CC",
			"0x407E8e19AC4aa2718ea84c90d499458cf05584A8",
			"0xD99D1c33F9fC3444f8101754aBC46c52416550D1",
		],
	},
];

verifyContracts(contractsToVerify);
