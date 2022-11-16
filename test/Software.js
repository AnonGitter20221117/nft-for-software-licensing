const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Software Smart Contract Unit Testing", function () {
	uri = "TEST_URI";

	async function deploySoftwareSC() {
		const Software = await ethers.getContractFactory("Software");
		const [dev, client] = await ethers.getSigners();
		const software = await Software.connect(dev).deploy(uri);
		await software.deployed();
		return {Software, software, dev, client};
	}

	describe("Deployment", function () {
		it("Should have correct URI", async function () {
			const {software, dev} = await loadFixture(deploySoftwareSC);
			console.log(await software.connect(dev).uri(0));
			console.log(uri);
			expect(await software.uri(0)).to.equal(uri);
		});
	});
});

// deploy(normal uri, normal from)
// addDistribution(normal cid, normal from)
// double call addDistribution(same cid, same from) + expect error
// addDistribution(normal cid, other from) + expect error
// grantSoftware(normal distId, normal user, normal from, normal value)
// double call grantSoftware(normal distId, normal user, normal from, normal value) + expect error
// grantSoftware(unobtained distId, normal user, normal from, normal value) + expect error
// grantSoftware(nonexistent distId, normal user, normal from, normal value) + expect error
// grantSoftware(normal distId, other user, normal from, normal value) + expect error
// grantSoftware(normal distId, normal user, other from, normal value) + expect error
// grantSoftware(normal distId, normal user, normal from, no value) + expect error
// grantSoftware(normal distId, normal user, normal from, high/available value) + expect error
// grantSoftware(normal distId, normal user, normal from, unavailable value) + expect error
