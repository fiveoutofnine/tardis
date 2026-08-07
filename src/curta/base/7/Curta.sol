// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "curta/interfaces/IPuzzle.sol";
import "./ChallFactory.sol";

contract FailedLendingMarket is IPuzzle {
    ChallFactory public challFactory;

    mapping(uint256 => Challenge) public instances;
    address public owner;

    constructor() {
        owner = msg.sender;
        challFactory = new ChallFactory(address(this));
    }

    function name() external pure returns (string memory) {
        return "CurtaLending";
    }

    function generate(address solver) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(solver)));
    }

    function verify(uint256 seed, uint256) external view returns (bool) {
        return instances[seed].isSolved();
    }

    function deploy() external returns (address) {
        uint256 seed = generate(msg.sender);
        instances[seed] = Challenge(challFactory.createChallenge(seed, msg.sender));

        return address(instances[seed]);
    }
}
