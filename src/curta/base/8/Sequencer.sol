// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./interfaces/IStateStorage.sol";
import "./interfaces/IRollApp.sol";

contract Sequencer {
    IStateStorage public immutable stateStorage;
    address public immutable owner;
    uint256 public constant MAX_STATE_COMMITMENTS = 5;
    IRollApp public rollApp;

    error InvalidCaller();
    error InvalidDestination();
    error InvalidDataLength(uint256 length);
    error InvalidBlockHeight(uint256 height, uint256 expectedHeight);
    error InvalidSubmitter(address submitter);
    error InvalidMerkleRoot();
    error PreviousMerkleRoot(bytes32 root);
    error ExceedsMaxCommitments(uint256 count);
    error Triggered();

    constructor(address _stateStorage) {
        owner = msg.sender;
        stateStorage = IStateStorage(_stateStorage);
    }

    function getStateCommitments() external view returns (bytes32[] memory) {
        return stateStorage.getStateCommitments();
    }

    function getMerkleProofRoot() external view returns (bytes32) {
        return stateStorage.getMerkleProofRoot();
    }

    function getStateNonce() external view returns (uint256) {
        return stateStorage.getStateNonce();
    }

    function getStateInitialized() external view returns (bool) {
        return stateStorage.getStateInitialized();
    }

    function compressStateCommitments(IStateStorage.State memory _state)
        external
        returns (bytes memory)
    {
        validateState(_state);
        bytes memory formattedData = _filterData(_state._data);
        stateStorage.setStateNonce(_state._blockHeight + 1);
        return abi.encode(_state._submitter, _state._blockHeight, _state._dst, formattedData);
    }

    function validateState(IStateStorage.State memory _state) public view {
        if (_state._submitter != address(tx.origin)) {
            revert InvalidSubmitter(_state._submitter);
        }
        if (
            _state._dst == address(0) || _state._dst == address(this)
                || _state._dst == address(stateStorage)
        ) {
            revert InvalidDestination();
        }
        if (_state._data.length > 0x400) {
            revert InvalidDataLength(_state._data.length);
        }
        if (_state._blockHeight > stateStorage.getStateNonce()) {
            revert InvalidBlockHeight(_state._blockHeight, stateStorage.getStateNonce());
        }
    }

    function setMerkleProofRoot(bytes32 _merkleProofRoot) external {
        bytes32[] memory stateCommitments = stateStorage.getStateCommitments();
        if (stateCommitments.length > MAX_STATE_COMMITMENTS) {
            revert ExceedsMaxCommitments(stateCommitments.length);
        }
        if (_merkleProofRoot == bytes32(0)) {
            revert InvalidMerkleRoot();
        }
        if (_merkleProofRoot == stateStorage.getMerkleProofRoot()) {
            revert PreviousMerkleRoot(_merkleProofRoot);
        }
        stateStorage.setMerkleProofRoot(_merkleProofRoot);
    }

    function setStateCommitments(IStateStorage.State[] memory _states) external {
        if (_states.length > MAX_STATE_COMMITMENTS) {
            revert ExceedsMaxCommitments(_states.length);
        }
        bytes32[] memory commitments = new bytes32[](_states.length);
        for (uint256 i = 0; i < _states.length; ++i) {
            commitments[i] = keccak256(abi.encodePacked(this.compressStateCommitments(_states[i])));
        }
        stateStorage.setStateCommitments(commitments);
    }

    function setRollApp(address _rollApp) external onlyOwner {
        rollApp = IRollApp(_rollApp);
    }

    function _filterData(bytes memory _data) internal pure returns (bytes memory) {
        assembly {
            let len := mload(_data)
            if gt(len, 4) {
                let _select := mload(add(_data, 0x20))
                if eq(_select, 0x00000000) { revert(0, 0) }
            }
        }
        return _data;
    }

    function formatData(bytes memory data) external returns (bytes memory) {
        assembly {
            let len := mload(data)
            for { let i := 4 } lt(i, len) { i := add(i, 1) } {
                let currentByte := mload(add(add(data, 0x20), i))

                currentByte := xor(currentByte, i)

                mstore(add(add(data, 0x20), i), currentByte)
            }
        }
        return data;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert InvalidCaller();
        }
        _;
    }

    receive() external payable {
        revert Triggered();
    }
}
