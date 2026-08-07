// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

uint256 constant BASE_PROOF_SIZE = 34;
uint256 constant SUBPROOF_LIMBS_SIZE = 16;

interface IVerifier {
    struct Proof {
        uint256[BASE_PROOF_SIZE] base;
        uint256[SUBPROOF_LIMBS_SIZE] subproofLimbs;
        uint256[] inputs;
    }

    /**
     * @notice Checks the validity of SNARK data
     * @param proof the proof to verify
     * @return the validity of the proof
     */
    function verify(Proof calldata proof) external view returns (bool);
}
