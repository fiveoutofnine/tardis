// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {F1A9} from "src/curta/eth/2/F1A9.sol";
import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(1, 2) {
    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice Address of the solver.
    address internal immutable solver;

    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The puzzle contract.
    IPuzzle internal puzzle;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Validates, sets, and labels the solver address.
    /// @dev `_solver` may not be the zero address, a precompile, the `owner`,
    /// the `mockAuthor`, or equal to any of the contracts'.
    /// @param _solver Address of the solver.
    constructor(address _solver) {
        _validateSolver(_solver);
        solver = _solver;
        vm.label(solver, "Solver");
    }

    /// @notice Deploys, labels, and adds the puzzle to the Curta contract.
    function setUp() public virtual override {
        super.setUp();

        // Deploy and label the puzzle contract.
        puzzle = IPuzzle(new F1A9());
        vm.label(address(puzzle), string.concat("Puzzle #2: ", puzzle.name()));

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 2);

        // Roll to block and warp to timestamp the puzzle was added initially: https://etherscan.io/tx/0xab168ef25e9ae2d6bf5bfacaa9f60bbad911d888e43ea51c392d088c5b936c9d
        vm.roll(16782325);
        vm.warp(1678291043);
    }
}
