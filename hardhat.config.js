const { task } = require("hardhat/config");

require("@nomicfoundation/hardhat-toolbox");

task("accounts", "Print all accounts and their balances", async (params, hre) => {
  const signers = await hre.ethers.getSigners();
  for (const signer of signers) {
    const balance = await signer.getBalance();
    console.log(signer.address, hre.ethers.utils.formatEther(balance), "ETH");
  }
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  gasReporter: {
    enabled: true,
    showMethodSig: true,
    showTimeSpent: true
  }
};
