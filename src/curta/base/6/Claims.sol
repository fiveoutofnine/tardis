// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IVerifier} from "./interfaces/IVerifier.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract Claims {
    using SafeERC20 for IERC20;

    struct Claim {
        bytes32 proofHash;
        uint32 timestamp;
        bool finalized;
        bool refuted;
        address recipient;
    }

    uint256 constant CHALLENGE_WINDOW = 1 days;

    IVerifier public immutable proofVerifier;
    IERC20 public immutable bondToken;
    uint256 public immutable bondAmount;

    mapping(address => bool) public validator;

    uint256 public nextClaimId;
    mapping(uint256 => Claim) public claims;

    constructor(IVerifier verifier, IERC20 token, uint256 amount) {
        proofVerifier = verifier;
        bondToken = token;
        bondAmount = amount;
        validator[msg.sender] = true;
    }

    modifier onlyValidator() {
        require(validator[msg.sender], "only validators can make claims");
        _;
    }

    function makeClaim(
        IVerifier.Proof calldata proof
    ) external onlyValidator returns (uint256 id) {
        bytes32 proofHash = keccak256(abi.encode(proof));
        bondToken.safeTransferFrom(msg.sender, address(this), bondAmount);
        id = nextClaimId++;
        claims[id] = Claim(
            proofHash,
            uint32(block.timestamp),
            false,
            false,
            msg.sender
        );
    }

    function finalizeClaim(uint256 id) external {
        Claim memory claim = claims[id];

        require(claim.proofHash != bytes32(0), "claim does not exist");
        require(
            (block.timestamp < uint256(claim.timestamp) + CHALLENGE_WINDOW) ||
                claim.refuted,
            "must have passed the challenge window or been successfully challenged"
        );
        claims[id].finalized = true;
        bondToken.safeTransfer(claim.recipient, bondAmount);
    }

    function disputeClaim(uint256 id, bytes calldata proof) external {
        Claim memory claim = claims[id];
        require(
            keccak256(proof) == claim.proofHash,
            "incorrect proof preimage provided"
        );

        IVerifier.Proof memory decodedProof = abi.decode(
            proof,
            (IVerifier.Proof)
        );

        bool valid;
        try proofVerifier.verify(decodedProof) returns (bool result) {
            valid = result;
        } catch { }
        require(!valid, "proof is actually valid");
        claims[id].refuted = true;
        claims[id].recipient = msg.sender;
    }
}
