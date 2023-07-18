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
		address: "0x9a686a0250058cb5Cffa15FdA62768a14e7Da20D",
		args: [],
	},
];

verifyContracts(contractsToVerify);
