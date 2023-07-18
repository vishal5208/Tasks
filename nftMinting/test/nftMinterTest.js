const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const intervalBetween = 10;

describe("NFTMinter", function () {
	let nftMinter, accounts, timestamp;
	beforeEach(async () => {
		accounts = await ethers.getSigners();

		// get current blocktime
		timestamp = (await time.latest()) + 2;

		// deploy NFTMinter
		// initial phase is of 300 seconds
		nftMinter = await ethers.deployContract("NFTMinter", []);

		await nftMinter.waitForDeployment();
	});

	it("integrated testing", async function () {
		////////////// check the inital pahse //////////////

		// get current blocktime
		timestamp = await time.latest();

		////////////// add 2 more phases //////////////
		let startTime = (await time.latest()) + 2;

		const tx = await nftMinter.addPhase(startTime, startTime + intervalBetween);

		await expect(tx)
			.to.emit(nftMinter, "NewPhaseAdded")
			.withArgs(1, startTime, startTime + intervalBetween);

		////////////// add a wallet as whitelisted //////////////

		const updatetx = await nftMinter.updateWhitelistForPhase(
			accounts[1].address,
			1,
			true
		);

		await expect(updatetx)
			.to.emit(nftMinter, "UpdatedWhiteList")
			.withArgs(1, accounts[1].address, true);

		// check the added is whitelisted or not
		const isAddrWhitelisted = await nftMinter.getWhitelist(
			accounts[1].address,
			1
		);

		assert(isAddrWhitelisted);

		// ////////////// user mints nft in ongoing phase //////////////

		await network.provider.send("evm_increaseTime", [8]);
		await network.provider.send("evm_mine", []);

		const minetx = await nftMinter.connect(accounts[1]).mintNFT();
	});
});
