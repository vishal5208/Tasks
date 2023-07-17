const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("VDToken", function () {
	let vDToken;
	let ownerAddr;
	let userAddr;
	let feeCollectorAddr;

	beforeEach(async () => {
		accounts = await ethers.getSigners();
		ownerAddr = accounts[0].address;
		feeCollectorAddr = accounts[1].address;
		userAddr = accounts[3].address;

		// deploy usdcToken contract
		vDToken = await ethers.deployContract("VDToken", [
			ownerAddr,
			feeCollectorAddr,
			"0x93bcdc45f7e62f89a8e901dc4a0e2c6c427d9f25",
		]);

		await vDToken.waitForDeployment();
	});

	it("integrated testing", async function () {
		// Check name, symbol, and decimal
		const name = await vDToken.name();
		const symbol = await vDToken.symbol();
		const decimals = await vDToken.decimals();

		assert.equal(name, "VDToken");
		assert.equal(symbol, "VD");
		assert.equal(decimals.toString(), "18");
		console.log(name, symbol, decimals);

		// Transfer tokens between accounts
		let ownerBalanceBefore = await vDToken.balanceOf(ownerAddr);
		let userBalanceBefore = await vDToken.balanceOf(userAddr);

		await vDToken.transfer(userAddr, ethers.parseUnits("100", decimals));

		let ownerBalanceAfter = await vDToken.balanceOf(ownerAddr);
		let userBalanceAfter = await vDToken.balanceOf(userAddr);
		let feeCollectorBal = await vDToken.balanceOf(feeCollectorAddr);

		let ownerDiff = ethers.formatEther(
			(ownerBalanceBefore - ownerBalanceAfter).toString()
		);

		let userDiff = ethers.formatEther(
			(userBalanceAfter - userBalanceBefore).toString()
		);

		// feecollector bal is 0 as owner is exclucded from tax

		assert.equal(ownerDiff, "100.0");
		assert.equal(userDiff, "100.0");
		assert.equal(feeCollectorBal.toString(), "0");

		// now user transfer 50VD back to owner
		ownerBalanceBefore = await vDToken.balanceOf(ownerAddr);
		userBalanceBefore = await vDToken.balanceOf(userAddr);

		await vDToken
			.connect(accounts[3])
			.transfer(accounts[5].address, ethers.parseUnits("50", decimals));

		ownerBalanceAfter = await vDToken.balanceOf(ownerAddr);
		userBalanceAfter = await vDToken.balanceOf(userAddr);
		feeCollectorBal = await vDToken.balanceOf(feeCollectorAddr);

		ownerDiff = ethers.formatEther(
			(ownerBalanceBefore - ownerBalanceAfter).toString()
		);

		userDiff = ethers.formatEther(
			(userBalanceAfter - userBalanceBefore).toString()
		);

		console.log(feeCollectorBal.toString());
	});
});
