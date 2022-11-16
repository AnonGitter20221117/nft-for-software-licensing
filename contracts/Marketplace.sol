// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Software.sol";
import "./Aggregator.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";


contract Marketplace {
	/**
	 * Structs
	 */
	// TODO: Maybe try merging DistListing and DistProps into big DistProps
	struct DistListing {
		// TODO: probably should have software author here
		address software; // address of software ERC-1155 contract
		uint256 distId; // token id representing the distribution
		uint256 price; // listing price suggested by software author

		uint256 weight; // weight of the distribution reflecting its importance (grabbed by oracles from Aggregator.sol)
		uint256 depsWeight; // total weights of dependencies
		uint256[] deps;
		// uint256 depCount; // number of dependencies
		// mapping(uint256 => uint256) deps; // what are the dependencies (maps to distId, which maps to DistListing)

		uint256 balance;
	}
	// struct DistProps {
	// 	uint256 weight;
	// 	uint256 dependenciesWeight;
	// 	uint256 dependenciesCount;
	// 	mapping(uint256 => uint256) dependencies;
	// 	mapping(uint256 => uint256) prices; // TODO: what?!
	// }


	/**
	 * Attributes
	 */
	address private deployer;
	address private aggregator; // TODO: this better or have 'Aggregator private aggregator'?
	
	// TODO: these should be called listings
	uint256 private listingsCount;
	mapping(uint256 => DistListing) private listings; // listingId => DistListing
	// mapping(uint256 => DistProps) private listings; // listingId => DistProps
	

	/**
	 * Functions
	 */
	constructor () {
		deployer = msg.sender;
		console.log("I am here deploying the Marketplace!");
	}
	function setAggregator(address _aggregator) external {
		// TODO: require only deployer
		aggregator = _aggregator;
	}
	// TODO: It's not the developer who decides the weight and depsWeight
	function addListing(
		address _software,
		uint256 _distId,
		uint256 _price, // TODO: what if author only wants price XOR royalty, not both? add acceptRoyalty? require other listings that use this one as dependency to obtain the software?
		uint256[] memory _deps) public payable {
		require(Address.isContract(_software), "Marketplace: Software must be a contract");
		// TODO: Require _software is an ERC-1155 (cannot do)
		// TODO: Require _software is a proper Software contract (cannot do)

		// TODO: fix this (check if still needed after moving from mapping to array)
		// require(_depsWeight == 0 && _dependencies.length == 0 ||
		// 	_depsWeight > 0 && _dependencies.length > 0,
		// 	"Marketplace: Invalid dependency input");
		
		listings[listingsCount].software = _software;
		listings[listingsCount].distId = _distId;
		listings[listingsCount].price = _price;
		
		Aggregator(payable(aggregator)).initiate
			{
				value: msg.value
			}
			(
				listingsCount,
				bytes4(keccak256(bytes("setListingWeight(uint256,uint256)"))),
				0,
				1 hours
			); // TODO: let author decide these parameters?

		listings[listingsCount].depsWeight = 0;
		uint256 _depsWeight = 0;
		for (uint256 i = 0; i < _deps.length; i++) {
			_depsWeight += listings[_deps[i]].weight + listings[_deps[i]].depsWeight;
		}
		listings[listingsCount].depsWeight = _depsWeight;

		listings[listingsCount].deps = _deps;
		
		console.log(
			"Added software %s (dist %s) of listingId %s",
			listings[listingsCount].software,
			listings[listingsCount].distId,
			listingsCount);
		console.log(
			"weight: %s, dependecies weight: %s (%s dependencies)",
			listings[listingsCount].weight,
			listings[listingsCount].depsWeight,
			listings[listingsCount].deps.length);
		listingsCount += 1;
	}
	function setListingWeight(uint256 _paramId, uint256 _result) external {
		listings[_paramId].weight = _result;
		console.log("Received listings %s weight: %s",
			_paramId,
			listings[_paramId].weight);
	}

	function obtain(uint256 _distId) public payable {
		require(msg.value == listings[_distId].price, "Marketplace: Price is inaccurate");
		Software(payable(listings[_distId].software))
			.grantSoftware(listings[_distId].distId, msg.sender);
		console.log("%s obtained dist %s for %s",
			msg.sender,
			_distId,
			msg.value);
		console.log("Dist %s balance from %s to %s",
			_distId,
			listings[_distId].balance,
			listings[_distId].balance + msg.value);
		listings[_distId].balance += msg.value;
	}
	function withdraw(uint256 _distId) public payable {
		uint256 _distBal = listings[_distId].balance;
		uint256 _weight = listings[_distId].weight;
		uint256 _totalWeight = _weight + listings[_distId].depsWeight;

		Address.sendValue(
			payable(listings[_distId].software),
			_distBal * _weight / _totalWeight);
		console.log("Sent %s to %s",
			_distBal * _weight / _totalWeight,
			listings[_distId].software);

		uint256 _depsLength = listings[_distId].deps.length;
		for (uint256 i = 0; i < _depsLength; i++) {
			uint256 _depsWeight = listings[i].weight;
			uint256 _depsDepsWeight = listings[i].depsWeight;
			console.log("Dist %s balance from %s to %s",
				i,
				listings[i].balance,
				listings[i].balance + _distBal * (_depsWeight + _depsDepsWeight) / _totalWeight);
			listings[i].balance += _distBal * (_depsWeight + _depsDepsWeight) / _totalWeight;
		}

		listings[_distId].balance = 0;
	}

	// function buySoftware(uint256 _distId) public payable {
	// 	require(msg.value == listings[_distId].price, "Marketplace: Price is inaccurate"); // TODO: here it should match sum of all prices :)
	// 	Software softwareSC = Software(payable(listings[_distId].software));
	// 	if (msg.value == 0) {
	// 		softwareSC.grantSoftware(listings[_distId].distId, msg.sender);
	// 	} else {
	// 		console.log(
	// 			"GrantSoftware: Sent payment of %s from %s to %s",
	// 			msg.value * listings[_distId].weight / (listings[_distId].weight + listings[_distId].depsWeight),
	// 			msg.sender,
	// 			listings[_distId].software);
	// 		softwareSC.grantSoftware
	// 			{value: msg.value * listings[_distId].weight / (listings[_distId].weight + listings[_distId].depsWeight)}
	// 			(listings[_distId].distId, msg.sender);
	// 		if (listings[_distId].depsWeight > 0) {
	// 			this.distributeRoyalties
	// 				{value: msg.value * listings[_distId].depsWeight / (listings[_distId].weight + listings[_distId].depsWeight)}
	// 				(_distId);
	// 		}
	// 	}
	// }
	// // TODO: No way to make this private or internal?
	// function distributeRoyalties(uint256 _distId) external payable {
	// 	uint256 dependenciesCount = listings[_distId].deps.length;
	// 	uint256 dependenciesWeight = listings[_distId].depsWeight;
	// 	for (uint256 i = 0; i < dependenciesCount; i++) {
	// 		uint256 dependency = listings[_distId].deps[i];
	// 		console.log(
	// 			"PayRoyalties: Sent payment of %s from %s to %s",
	// 			msg.value * listings[dependency].weight / dependenciesWeight,
	// 			msg.sender,
	// 			listings[dependency].software);
	// 		Address.sendValue(
	// 			payable(listings[dependency].software), 
	// 			msg.value * listings[dependency].weight / dependenciesWeight);
	// 		if (listings[dependency].depsWeight > 0) {
	// 			this.distributeRoyalties
	// 				{value: msg.value * listings[dependency].depsWeight / dependenciesWeight}
	// 				(dependency);
	// 		}
	// 	}
	// }
}
