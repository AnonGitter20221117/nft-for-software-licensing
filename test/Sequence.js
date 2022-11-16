const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Software + Marketplace + Aggregator Integration Testing", () => {
	let aggregator, marketplace, softwareA, softwareB;
	let signers;

	before("Getting signers", async () => {
		signers = await ethers.getSigners();
	});
	
	it("Deploy all smart contracts", async () => {
		const Aggregator = await ethers.getContractFactory("Aggregator");
		const Marketplace = await ethers.getContractFactory("Marketplace");
		const Software = await ethers.getContractFactory("Software");

		aggregator = await Aggregator.connect(signers[0]).deploy();
		marketplace = await Marketplace.connect(signers[1]).deploy();
		softwareA = await Software.connect(signers[2]).deploy("ipns:QmUEMvxS2e7iDrereVYc5SWPauXPyNwxcy9BXZrC1QTcHE/{id}");
		softwareB = await Software.connect(signers[3]).deploy("https://github.com/username/{id}");

		await aggregator.deployed();
		await marketplace.deployed();
		await softwareA.deployed();
		await softwareB.deployed();
	});

	it("Set Marketplace properties (Aggregator)", async () => {
		await marketplace.connect(signers[1]).setAggregator(aggregator.address);
	});

	it("Add distribution A0 and list it on Marketplace", async () => {
		await softwareA.connect(signers[2]).addDist("sha3:a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26");
		await marketplace.connect(signers[2]).addListing(
			softwareA.address,
			0,
			0,
			[],
			{value: ethers.utils.parseEther("0.5")});
		await aggregator.connect(signers[5]).aggregate(1, 50);
		await aggregator.connect(signers[6]).aggregate(1, 60);
		await aggregator.connect(signers[7]).aggregate(1, 58);
		await aggregator.connect(signers[8]).finalize(1);
		await aggregator.connect(signers[2]).rate(1, signers[5].address, -20);
		await aggregator.connect(signers[2]).rate(1, signers[6].address, 100);
		await aggregator.connect(signers[2]).rate(1, signers[7].address, 90);
	});

	it("Add distribution B0 and list it on Marketplace", async () => {
		await softwareB.connect(signers[3]).addDist("sha3:203b36aac62037ac7c4502aa023887f7fcae843c456fde083e6a1dc70a29f3d61a73f57d79481f06e27ea279c74528e1ba6b1854d219b1e3b255729889ca5926");
		await marketplace.connect(signers[3]).addListing(
			softwareB.address,
			0,
			ethers.utils.parseEther("1.5"),
			[0],
			{value: ethers.utils.parseEther("0.3")});
		await aggregator.connect(signers[6]).aggregate(2, 25);
		await aggregator.connect(signers[7]).aggregate(2, 50);
		await aggregator.connect(signers[8]).aggregate(2, 30);
		await aggregator.connect(signers[9]).aggregate(2, 30);
		await aggregator.connect(signers[10]).finalize(2);
		await aggregator.connect(signers[3]).rate(2, signers[6].address, -50);
		await aggregator.connect(signers[3]).rate(2, signers[7].address, 20);
		await aggregator.connect(signers[3]).rate(2, signers[8].address, 100);
		await aggregator.connect(signers[9]).unlock();
	});

	it("Obtain distribution A0 from Marketplace", async () => {
		await marketplace.connect(signers[4]).obtain(
			1,
			{value: ethers.utils.parseEther("1.5")});
		// await softwareB.connect(signers[4]).rate(0, 200);
		await softwareB.connect(signers[4]).rate(0, 100);
		// await softwareB.connect(signers[4]).rate(0, -40);
	});

	it("Withdrawing balance from Marketplace", async () => {
		await marketplace.connect(signers[3]).withdraw(1);
		await marketplace.connect(signers[2]).withdraw(0);
	});
});
