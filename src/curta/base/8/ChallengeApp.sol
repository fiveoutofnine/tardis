// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "curta/interfaces/IPuzzle.sol";

/**
 * @title RollApp Sequencer Challenge
 * @author ChainLight / https://x.com/chainlight_io
 * @notice This contract receives data from the rollApp based on pre-allowed addresses and interacts with the rollApp through shared sequencing based on compressed data.
 */
contract ChallengeApp is IPuzzle {
    address public rollApp;
    address public stateStorage;
    address public owner;

    error InvalidCaller();
    error InvalidSolution();
    error InvalidRollAppCaller();

    mapping(address => mapping(bytes32 => bool)) internal _rollAppStatesReceived;

    constructor(address _stateStorage, address _rollApp) {
        rollApp = _rollApp;
        stateStorage = _stateStorage;
        owner = msg.sender;
    }

    function recvRollAppData(bytes32 solutionCode) external onlyRollApp returns (bool) {
        if (solutionCode == bytes32(0)) {
            return false;
        }
        _rollAppStatesReceived[tx.origin][solutionCode] = true;
        return true;
    }

    function name() external pure returns (string memory) {
        return "RollApp Sequencer Challenge";
    }

    function generate(address seed) external view returns (uint256) {
        return uint256(uint160(seed));
    }

    function verify(uint256 seed, uint256 solution) external view returns (bool) {
        address solver = address(uint160(seed));
        if (solution != uint256(uint128(uint256(keccak256(abi.encode(seed)))))) {
            revert InvalidSolution();
        }

        bytes32 solutionCode = keccak256(abi.encodePacked(seed, solution));
        return _rollAppStatesReceived[solver][solutionCode];
    }

    modifier onlyRollApp() {
        if (msg.sender != rollApp) {
            revert InvalidRollAppCaller();
        }
        _;
    }
}
