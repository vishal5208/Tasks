const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

const baseFee = "250000000000000000"; // 0.25 is this the premium in LINK?
const gasPriceLink = 1e9; // link per gas, is this the gas lane? // 0.000000001 LINK per gas
const vrfSubFundAmount = ethers.parseEther("1");
const entranceFee = ethers.parseEther("1");

const gasLane =
	"0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15";
const interval = 5;
const callBackGasLimit = "500000";

describe("OddEvenGame", function () {
	let oddEvenGame, accounts;
	beforeEach(async () => {
		accounts = await ethers.getSigners();

		// deploy VRFCoordinatorV2Mock
		vrfCoordinatorV2Mock = await ethers.deployContract("VRFCoordinatorV2Mock", [
			baseFee,
			gasPriceLink,
		]);
		await vrfCoordinatorV2Mock.waitForDeployment();

		// for subscritpion id
		const tx = await vrfCoordinatorV2Mock.createSubscription();
		const txRec = await tx.wait();

		const subscriptionId = txRec.logs[0].args[0].toString();

		// we have the subscription, now fund the subscription
		await vrfCoordinatorV2Mock.fundSubscription(
			subscriptionId,
			vrfSubFundAmount
		);

		// deploy usdcToken contract
		oddEvenGame = await ethers.deployContract("OddEvenGame", [
			vrfCoordinatorV2Mock.target,
			entranceFee,
			gasLane,
			subscriptionId,
			callBackGasLimit,
			interval,
		]);

		await oddEvenGame.waitForDeployment();

		// add customer to vrf
		await vrfCoordinatorV2Mock.addConsumer(subscriptionId, oddEvenGame.target);
	});

	it("integrated testing", async function () {
		// 9 accounts enter the oddEvenGame

		for (let i = 1; i < 10; i++) {
			// Generate a random number between 0 and 1
			const randomValue = Math.random();

			// Convert the random value to 0 or 1
			const randomNumber = randomValue < 0.5 ? 0 : 1;

			console.log(randomNumber);

			await expect(
				oddEvenGame.connect(accounts[i]).enterToOddEvenGame(randomNumber, {
					value: entranceFee,
				})
			)
				.to.emit(oddEvenGame, "OddEvenGameEnter")
				.withArgs(accounts[i].address);
		}

		// increase the evm time
		await network.provider.send("evm_increaseTime", [interval + 1]);

		// mine one block also
		await network.provider.send("evm_mine", []);

		const { upKeepNeeded } = await oddEvenGame.checkUpkeep("0x");
		assert(upKeepNeeded);

		// call perform upkeep

		const performTx = await oddEvenGame.performUpkeep("0x");
		const perfromTxRec = await performTx.wait();

		// call fulfillRandomWords
		const fullFillTx = await vrfCoordinatorV2Mock.fulfillRandomWords(
			perfromTxRec.logs[1].args[0],
			oddEvenGame.target
		);

		await fullFillTx.wait();

		const winners = await oddEvenGame.getWinners();
		console.log(winners);

		
	});
});
