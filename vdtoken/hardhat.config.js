require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: {
		version: "0.8.4",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	networks: {
		polygonMumbai: {
			url: process.env.POLYGON_TESTNET_URL,
			accounts: [process.env.PRIVATE_KEY],
		},

		bnbSmartChain: {
			url: "https://data-seed-prebsc-1-s1.binance.org:8545",
			chainId: 97,
			accounts: [process.env.PRIVATE_KEY],
		},

		testnet: {
			url: "https://data-seed-prebsc-1-s1.binance.org:8545",
			chainId: 97,
			gasPrice: 20000000000,
			accounts: [process.env.PRIVATE_KEY],
		},

		hardhat: {
			chainId: 31337,
			forking: {
				url: process.env.POLYGON_MAINNETFORK_URL,
			},
		},
	},

	etherscan: {
		apiKey: {
			bscTestnet: process.env.BSC_API_KEY,
		},
	},
};
