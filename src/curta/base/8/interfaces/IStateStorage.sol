// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IStateStorage {
    function getStateCommitments() external view returns (bytes32[] memory);
    function getMerkleProofRoot() external view returns (bytes32);
    function getStateInitialized() external view returns (bool);
    function getStateNonce() external view returns (uint256);
    function setStateCommitments(bytes32[] memory _stateCommitments) external;
    function setMerkleProofRoot(bytes32 _merkleProofRoot) external;
    function setStateNonce(uint256 _stateNonce) external;

    // state struct
    struct State {
        address _submitter;
        address _dst;
        uint256 _blockHeight;
        bytes _data;
    }
}
