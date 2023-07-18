const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const getCurrentBlockTimestamp = async () => {
	const blockNumber = await ethers.provider.getBlockNumber();
	const block = await ethers.provider.getBlock(blockNumber);

	return block.timestamp;
};

describe("NFTMinter", function () {
	let nftMinter, accounts;
	beforeEach(async () => {
		accounts = await ethers.getSigners();

		// get current blocktime
		// const startTime = getCurrentBlockTimestamp();
		const timestamp = await time.latest();
		console.log(timestamp);

		// deploy NFTMinter
		// nftMinter = await ethers.deployContract("NFTMinter", []);
		// await nftMinter.waitForDeployment();
	});

	it("integrated testing", async function () {
		console.log("vishal");
	});
});
