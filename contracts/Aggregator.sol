// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// DO NOT IMPORT ANY OTHER LOCAL FILE
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

// TODO: is ratable
contract Aggregator {
	/**
	 * Enums
	 */
	/**
	 * Structs
	 */
	struct Request {
		address requester; // must be a smart contract
		uint256 paramId; // identifies parameters at requester SC -> requests[id]
		// TODO: maybe no need for callback? maybe requester can fetch the information from own contract? or... any contract that imports aggregator MUST implement a function of some fixed name (getAggregatorResult)
		bytes4 callback; // what function of requester to call once done
		int256 score; // participating processor must not have a score lower than 'score'
		uint256 deadline; // if request has final result, must return result once 'deadline' arrives, else, wait for any result and return result
		uint256 reward; // what the requester paid for the request
		uint256 result; // aggregated (mean) result
		uint256 inputs; // number of inputs by processors
	}
	struct Processor {
		uint256 requestId; // active requestId the processor is locked to working on and finalizing, requestId = 0 means processor is unlocked
		int256 score;
		uint256 ratings;
	}

	/**
	 * Attributes
	 */
	address private deployer;
	uint256 private requestCount;
	mapping(uint256 => Request) private requests;
	mapping(address => Processor) private processors;

	/**
	 * Modifiers
	 */
	/**
	 * Functions
	 */
	// constructor
	constructor() {
		deployer = msg.sender;
		requestCount = 1;
	}
	receive() external payable {}

	// initiate (start new aggregation request + hold payment)
	function initiate(
		uint256 _paramId,
		bytes4 _callback,
		int256 _score,
		uint256 _within)
	external payable returns (uint256 requestId) {
		// TODO: require msg.sender is contract
		// TODO: require now+period is in the future
		// TODO: require to prevent resetting existing requests
		
		requests[requestCount].requester = msg.sender;
		requests[requestCount].paramId = _paramId; // TODO: no need to store, just emit
		requests[requestCount].callback = _callback;
		requests[requestCount].score = _score;
		requests[requestCount].reward = msg.value;
		requests[requestCount].deadline = block.timestamp + _within;
		
		requestId = requestCount; // TODO: this is not important lol
		// TODO: send event to processors, containing requestId
		
		console.log(
			"New request from %s, paramId %s... requestId=%s",
			msg.sender,
			_paramId,
			requestId);

		requestCount += 1;
	}
	// TODO: can add reset to re-initiate requests that never responded

	// aggregate (receive input and aggregate it into the final result)
	function aggregate(
		uint256 _requestId,
		uint256 _input
	) external {
		// TODO: require processor is not locked
		// TODO: require the request exists
		// TODO: require processor score equal or greater than requests.score
		// TODO: require have not reached requests.deadline yet

		uint256 _result = requests[_requestId].result;
		uint256 _inputs = requests[_requestId].inputs;
		_result = (_result * _inputs + _input) / (_inputs + 1); // TODO: look out for overflows
		_inputs += 1;
		requests[_requestId].result = _result;
		requests[_requestId].inputs = _inputs;

		console.log(
			"New input (value=%s) for request %s, result is now %s",
			_input,
			_requestId,
			_result);
	}
	// function late(
	// 	uint256 _requestId,
	// 	uint256 _response
	// ) external {
	// 	// require processor is not locked
	// 	// require processor score equal or greater than requests.score
	// 	// require no response yet AND requests.deadline has reached
	// }

	// finalize (send response back to requester)
	function finalize(
		uint256 _requestId
	) external payable {
		// TODO: require the request exists (i.e. finalizable)
		// TODO: require reached requests.deadline 
		// TODO: require request has final result (i.e. finalizable)
		// TODO: require request is not already finalized (i.e. finalizable)

		bytes4 _callback = requests[_requestId].callback;
		uint256 _paramId = requests[_requestId].paramId;
		uint256 _result = requests[_requestId].result;
		(bool _success, bytes memory _data) = 
			address(requests[_requestId].requester)
				.call(abi.encodePacked(_callback, _paramId, _result));
		require(_success, string(_data));

		uint256 _reward = requests[_requestId].reward;
		uint256 _inputs = requests[_requestId].inputs;
		Address.sendValue(
			payable(msg.sender),
			_reward / (_inputs + 1)
		);
		console.log("Sent %s to %s, remaining balance: %s",
			_reward / (_inputs + 1),
			msg.sender,
			address(this).balance);
	}

	// rate (allow requester to rate processor while locked)
	// TODO: this will incentivize processors to give high weight, so that authors don't give them bad rating 👀
	function rate(
		uint256 _requestId,
		address _processor,
		int256 _rating
	) external payable {
		// TODO: require rating window has not passed
		// TODO: require requester of requestId is msg.sender (or benefeciary of requestId)
		// TODO: require request is finalized
		// TODO: require did not already rate the processor (processor.requestId = _requestId)

		console.log("Updating %s reputation score:",
			_processor);
		int256 _score = processors[_processor].score;
		uint256 _ratings = processors[_processor].ratings;
		console.log("Old score: ");
		console.logInt(_score);
		_score = (_score * int256(_ratings) + _rating) / (int256(_ratings) + 1);
		_ratings += 1;
		processors[_processor].requestId = 0;
		processors[_processor].score = _score;
		processors[_processor].ratings = _ratings;
		console.log("New score: ");
		console.logInt(_score);

		uint256 _reward = requests[_requestId].reward;
		uint256 _inputs = requests[_requestId].inputs;
		Address.sendValue(
			payable(_processor),
			_reward / (_inputs + 1)
		);
		console.log("Sent %s to %s, remaining balance: %s",
			_reward / (_inputs + 1),
			_processor,
			address(this).balance);
	}
	// unlock (allow processor to participate in other requests + distribute payment)
	function unlock()
	external payable {
		// TODO: require processor is locked meaning it's not yet paid
		// TODO: require requestId is finalized

		processors[msg.sender].requestId = 0;

		uint256 _requestId = processors[msg.sender].requestId;
		uint256 _reward = requests[_requestId].reward;
		uint256 _inputs = requests[_requestId].inputs;
		Address.sendValue(
			payable(msg.sender),
			_reward / (_inputs + 1)
		);
		console.log("Sent %s to %s, remaining balance: %s",
			_reward / (_inputs + 1),
			msg.sender,
			address(this).balance);
	}

}
