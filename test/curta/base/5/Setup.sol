// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(8453, 5) {
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

        // Deploy or load and label the puzzle contract.
        puzzle = IPuzzle(0xb24Ab66B4C6f52F6686FFD348b1cFf47c5E84FB5);
        vm.label(address(puzzle), "Puzzle #5: ZSafe");

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 5);
    }
}
