// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {MiniMutant} from "src/curta/eth/7/MiniMutant.sol";
import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(1, 7) {
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
        puzzle = IPuzzle(new MiniMutant());
        vm.label(address(puzzle), string.concat("Puzzle #7: ", puzzle.name()));

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 7);
    }
}
