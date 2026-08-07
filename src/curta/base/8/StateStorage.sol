// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract StateStorage {
    struct State {
        address _submitter;
        address _dst;
        uint256 _blockHeight;
        bytes _data;
    }

    address public owner;

    address public RollApp;
    address public Sequencer;

    bool public state_initialized;

    mapping(address => uint256) public stateNonce;
    mapping(address => bytes32[]) public stateCommitments;
    mapping(address => bytes32) public merkleProofRoot;

    event SetStateCommitments(address indexed _submitter, bytes32[] _stateCommitments);
    event SetMerkleProofRoot(address indexed _submitter, bytes32 _merkleProofRoot);
    event SetStateInitialized(address indexed _submitter, bool _state_initialized);
    event SetStateNonce(address indexed _submitter, uint256 _stateNonce);

    error InitializerError();
    error UnauthorizedCaller();

    constructor() {
        owner = msg.sender;
    }

    function initialize(address _rollApp, address _sequencer) public {
        if (state_initialized && !(owner == msg.sender)) {
            revert InitializerError();
        }
        RollApp = _rollApp;
        Sequencer = _sequencer;
        state_initialized = true;
    }

    function getStateCommitments() external view returns (bytes32[] memory) {
        return stateCommitments[tx.origin];
    }

    function getMerkleProofRoot() external view returns (bytes32) {
        return merkleProofRoot[tx.origin];
    }

    function getStateInitialized() external view returns (bool) {
        return state_initialized;
    }

    function getStateNonce() external view returns (uint256) {
        return stateNonce[tx.origin];
    }

    function setStateCommitments(bytes32[] memory _stateCommitments) public onlyAuthorized {
        stateCommitments[tx.origin] = _stateCommitments;

        emit SetStateCommitments(tx.origin, _stateCommitments);
    }

    function setMerkleProofRoot(bytes32 _merkleProofRoot) public onlyAuthorized {
        merkleProofRoot[tx.origin] = _merkleProofRoot;
        emit SetMerkleProofRoot(tx.origin, _merkleProofRoot);
    }

    function setStateNonce(uint256 _stateNonce) public onlyAuthorized {
        stateNonce[tx.origin] = _stateNonce;
        emit SetStateNonce(tx.origin, _stateNonce);
    }

    modifier onlyAuthorized() {
        if (
            msg.sender != address(owner) && msg.sender != address(RollApp)
                && msg.sender != address(Sequencer)
        ) {
            revert UnauthorizedCaller();
        }
        _;
    }
}
