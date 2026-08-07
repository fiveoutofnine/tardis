// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./IStateStorage.sol";

interface IRollApp {
    function execState(bytes32 _stateHash) external;
    function updateState(IStateStorage.State memory _state, bytes32[] calldata proof)
        external
        returns (bytes32);
    function handleState(IStateStorage.State memory _state) external;
    function getCommitments(bytes32 _leaf) external view returns (bool);
}
