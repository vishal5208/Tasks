const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const intervalBetween = 300;

describe("NFTMinter", function () {
	let nftMinter, accounts, timestamp;
	beforeEach(async () => {
		accounts = await ethers.getSigners();

		// get current blocktime
		timestamp = (await time.latest()) + 2;
		// console.log(timestamp);

		// deploy NFTMinter
		// initial phase is of 300 seconds
		nftMinter = await ethers.deployContract("NFTMinter", [
			timestamp,
			timestamp + intervalBetween,
		]);
		await nftMinter.waitForDeployment();
	});

	it("integrated testing", async function () {
		////////////// check the inital pahse //////////////
		const [phase1StartTime, phase1EndTime] = await nftMinter.getWhitelistPhases(
			"1"
		);

		// get current blocktime
		timestamp = await time.latest();

		assert(
			timestamp < phase1StartTime.toString() &&
				phase1EndTime.toString() > phase1StartTime.toString()
		);

		////////////// add 4 more phases //////////////
		let startTime = (await time.latest()) + 400; // each phase is of 300 seconds
		for (let i = 0; i < 4; i++) {
			const tx = await nftMinter.addPhase(
				startTime,
				startTime + intervalBetween
			);

			await expect(tx)
				.to.emit(nftMinter, "NewPhaseAdded")
				.withArgs(i + 2, startTime, startTime + intervalBetween);

			startTime += 400;
		}

		////////////// for each phase add 2 wallets as whitelisted //////////////
		// 0-> 	0 1 -> i + 0 , i+1
		// 1 -> 	2 3  -> i+1 i+2
		// 2 -> 	4 5 -> i+2 i+3
		// 3 -> 	6 7 -> i+3 , i+4
		for (let i = 0; i < 4; i++) {
			for (let j = 2 * i; j < 2 * i + 2; j += 1) {
				const tx = await nftMinter.updateWhitelistForPhase(
					accounts[j].address,
					i + 1,
					true
				);

				await expect(tx)
					.to.emit(nftMinter, "UpdatedWhiteList")
					.withArgs(i + 1, accounts[j].address, true);

				// check the added is whitelisted or not
				const isAddrWhitelisted = await nftMinter.getWhitelist(
					accounts[j].address,
					i + 1
				);

				assert(isAddrWhitelisted);
			}

			////////////// user mints nft in ongoing phase  	//////////////
			
		}
	});
});
