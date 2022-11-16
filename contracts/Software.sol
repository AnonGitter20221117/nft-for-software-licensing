// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";


contract Software is ERC1155 {
	/**
	 * Structs
	 */
	struct Dist {
		string cid; // TODO: cid is unnecessary becuase it can be put inside uri/{id}, think of something else to put here or just remove Dist altogether
		int score;
		uint256 ratings;
	}


	/**
	 * Attributes
	 */
	address payable private deployer;
	uint256 private distsCount;
	mapping(uint256 => Dist) private dists;
	mapping(address => mapping(uint256 => bool)) canRateDist;
	mapping(address => bool) private didRate;

	/**
	 * Functions
	 */
	constructor(string memory _uri) ERC1155(_uri) {
		deployer = payable(msg.sender);
	}
	receive() external payable {
		Address.sendValue(deployer, msg.value);
		console.log("ForwardPayment: Forward payment of %s to %s", msg.value, deployer);
	}
	function addDist(string memory _cid) public {
		require(deployer == msg.sender, "Software: Callable by deployer only");
		dists[distsCount].cid = _cid;
		distsCount += 1;
	}
	function grantSoftware(uint256 _distId, address _user) public payable {
		_mint(_user, _distId, 1, "");
		Address.sendValue(deployer, msg.value);
		canRateDist[_user][_distId] = true;
		console.log(
			"GrantSoftware: Forward payment of %s to %s",
			msg.value,
			deployer);
		console.log(
			"GrantSoftware: Minted 1 copy of software %s (dist %s) to %s",
			address(this),
			_distId,
			_user);
	}
	function rate(
		uint256 _distId,
		int256 _rating
	) external {
		// TODO: require canRateDist is true
		// TODO: think of other requires
		console.log("Updating %s rating score:",
			_distId);
		int256 _score = dists[_distId].score;
		uint256 _ratings = dists[_distId].ratings;
		console.log("Old score: ");
		console.logInt(_score);
		_score = (_score * int256(_ratings) + _rating) / (int256(_ratings) + 1); // TODO: think of overflow (max score max ratings combination to fit in uint256 and in256)
		_ratings += 1;
		dists[_distId].score = _score;
		dists[_distId].ratings = _ratings;
		console.log("New score: ");
		console.logInt(_score);

		canRateDist[msg.sender][_distId] = true;
	}
}

// %% Software.sol Functions (as in sequence diagrams)
// % Developer ->> Deploy + Universal URI [done -- constructor]
// % Developer ->> Add distribution [done -- addDist]
// % Marketplace.sol ->> New payment (send to address of developer) [done -- receive]
// % Marketplace.sol ->> Client obtained software (mint distribution NFT for client) [done -- grantSoftware]
// Client ->> Rate obtained distribution

// %% Functions
// % Add project
// % Update project
// % Mint project
// % Buy project and royalties
// % Rate project 
// % Add/remove/update license options (maybe later hehe)

// %% Options
// % Open-source | Partial | Proprietary (whether source code is available to the public fully, partially, or not at all, can depend on license)
// % Perpetual license | Subscription license | Multiple (these are general types, each listed license can have more defined terms and conditions)
// % Dependencies (royalties) (keep going up the tree unless have a perpetual license that says don't have to pay)
// % Multiple developers (owners)