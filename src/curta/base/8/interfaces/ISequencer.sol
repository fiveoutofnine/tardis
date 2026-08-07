// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./IStateStorage.sol";

interface ISequencer is IStateStorage {
    function getStateCommitments() external view returns (bytes32[] memory);
    function getMerkleProofRoot() external view returns (bytes32);
    function getStateNonce() external view returns (uint256);
    function compressStateCommitments(IStateStorage.State memory _state)
        external
        returns (bytes memory);
    function encodeRollAppCallData(bytes memory _data)
        external
        view
        returns (bytes memory _encodeData);
    function formatData(bytes memory data) external returns (bytes memory);
    function setRollApp(address _rollApp) external;
    function setMerkleProofRoot(bytes32 _merkleProofRoot) external;
    function setStateCommitments(IStateStorage.State[] memory _states) external;
}
