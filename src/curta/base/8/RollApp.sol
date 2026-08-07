// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/IStateStorage.sol";
import "./interfaces/ISequencer.sol";

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

contract RollApp {
    IStateStorage public stateStorage;
    ISequencer public sequencer;
    uint256 public maxData;

    mapping(address => mapping(bytes32 => bool)) public commitments;
    mapping(address => mapping(bytes32 => IStateStorage.State)) internal stateFinalized;

    error InvalidCaller();
    error TransferFailed();
    error InvalidProof();
    error InvalidDataLength(uint256 dataLength, uint256 maxLength);
    error Sequenced();
    error FailedStateUpdate();

    event StateCommitmentsUpdated(address indexed, bytes32 indexed, bytes32, bytes32[]);
    event HandleState(address indexed, bool);
    event ExecState(address indexed, bytes32 indexed);

    constructor(uint256 _maxData, address _stateStorage, address _sequencer) {
        maxData = _maxData;
        stateStorage = IStateStorage(_stateStorage);
        sequencer = ISequencer(_sequencer);
    }

    function handleState(IStateStorage.State calldata _state) external {
        if (_state._data.length > maxData) {
            revert InvalidDataLength({ dataLength: _state._data.length, maxLength: maxData });
        }

        bytes memory formattedData = sequencer.compressStateCommitments(_state);
        bytes32 _leaf = keccak256(abi.encodePacked(formattedData));
        if (commitments[msg.sender][_leaf]) {
            revert Sequenced();
        }
        commitments[msg.sender][_leaf] = true;
        emit HandleState(msg.sender, true);
    }

    function execState(bytes32 _stateHash) external {
        IStateStorage.State memory _execStateData = stateFinalized[msg.sender][_stateHash];
        if (_execStateData._data.length == 0) {
            revert FailedStateUpdate();
        }

        bytes memory _seq_data = sequencer.formatData(_execStateData._data);
        delete stateFinalized[msg.sender][_stateHash];

        (bool success,) = address(_execStateData._dst).call(_seq_data);
        if (!success) {
            revert TransferFailed();
        }

        emit ExecState(msg.sender, _stateHash);
    }

    function updateState(IStateStorage.State calldata _state, bytes32[] calldata proof)
        external
        returns (bytes32)
    {
        return _verifyProof(_state, proof);
    }

    function _verifyProof(IStateStorage.State memory _state, bytes32[] calldata proof)
        internal
        returns (bytes32)
    {
        if (proof.length == 0) {
            revert InvalidProof();
        }

        bytes32 _leaf = keccak256(abi.encodePacked(sequencer.compressStateCommitments(_state)));
        if (commitments[msg.sender][_leaf]) {
            revert Sequenced();
        }

        if (!MerkleProofLib.verify(proof, stateStorage.getMerkleProofRoot(), _leaf)) {
            revert InvalidProof();
        }

        commitments[msg.sender][_leaf] = true;
        bytes32 _stateHash = keccak256(abi.encode(_state));
        stateFinalized[msg.sender][_stateHash] = _state;
        emit StateCommitmentsUpdated(msg.sender, _stateHash, _leaf, proof);
        return _stateHash;
    }

    function getCommitments(bytes32 _leaf) external view returns (bool) {
        return commitments[msg.sender][_leaf];
    }

    receive() external payable {
        revert InvalidCaller();
    }
}
