// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CheapMap} from "./lib/CheapMap.sol";

contract DAO {
    // gotta go fast
    uint256 constant REQUIRED_VOTES = 3;
    uint256 constant DURATION = 36;

    mapping(address => bool) targets;
    mapping(bytes4 => bool) methods;

    struct Proposal {
        address owner;
        uint64 end;
        uint32 votes;
        address target;
        bool executed;
    }

    mapping(uint256 => Proposal) proposals;
    mapping(address => mapping(uint256 => bool)) voted;

    constructor(
        address[] memory allowedTargets,
        bytes4[] memory allowedMethods
    ) {
        for (uint256 i = 0; i < allowedTargets.length; i++) {
            targets[allowedTargets[i]] = true;
        }

        for (uint256 i = 0; i < allowedMethods.length; i++) {
            methods[allowedMethods[i]] = true;
        }
    }

    modifier onlyOwner(uint256 id) {
        require(
            msg.sender == proposals[id].owner,
            "only proposal owner allowed"
        );
        _;
    }

    function validData(bytes memory data) internal view returns (bool) {
        return data.length >= 4 && methods[bytes4(data)];
    }

    function validTarget(address target) internal view returns (bool) {
        return targets[target];
    }

    function descriptionKey(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id, id));
    }

    function getDescription(uint256 id) public view returns (string memory) {
        return string(CheapMap.read(descriptionKey(id)));
    }

    function setDescription(uint256 id, string memory desc) internal {
        CheapMap.write(descriptionKey(id), bytes(desc));
    }

    function getData(uint256 id) public view returns (bytes memory) {
        return CheapMap.read(bytes32(id));
    }

    function setData(uint256 id, bytes memory data) internal {
        require(validData(data), "payload data not allowed");
        CheapMap.write(bytes32(id), data);
    }

    function createProposal(
        uint256 id,
        address target,
        bytes memory data,
        string memory desc
    ) external {
        require(proposals[id].owner == address(0), "proposal already exists");
        require(validTarget(target), "invalid payload target");

        proposals[id] = Proposal(
            msg.sender,
            uint64(block.timestamp + DURATION),
            1,
            target,
            false
        );

        setData(id, data);
        if (bytes(desc).length > 0) setDescription(id, desc);
    }

    function vote(uint256 id) external {
        Proposal storage proposal = proposals[id];
        require(proposal.owner != address(0), "proposal does not exist");
        require(block.timestamp <= uint256(proposal.end), "proposal ended");
        require(!voted[msg.sender][id], "already voted");
        voted[msg.sender][id] = true;
        proposal.votes++;
    }

    function execute(uint256 id) external returns (bytes memory) {
        require(proposals[id].votes >= REQUIRED_VOTES, "not enough votes");
        require(!proposals[id].executed, "already executed");

        (bool success, bytes memory result) = proposals[id].target.call(
            getData(id)
        );
        proposals[id].executed = success;
        return result;
    }
}
