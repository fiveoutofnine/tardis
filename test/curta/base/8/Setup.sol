// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {ChallengeApp} from "src/curta/base/8/ChallengeApp.sol";
import {RollApp} from "src/curta/base/8/RollApp.sol";
import {Sequencer} from "src/curta/base/8/Sequencer.sol";
import {StateStorage} from "src/curta/base/8/StateStorage.sol";

import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(8453, 8) {
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

        // Deploy the sequencing system used by the puzzle.
        StateStorage stateStorage = new StateStorage();
        Sequencer sequencer = new Sequencer(address(stateStorage));
        RollApp rollApp = new RollApp(0x400, address(stateStorage), address(sequencer));
        stateStorage.initialize(address(rollApp), address(sequencer));
        sequencer.setRollApp(address(rollApp));

        // Deploy and label the puzzle contract.
        puzzle = IPuzzle(address(new ChallengeApp(address(stateStorage), address(rollApp))));
        vm.label(address(puzzle), "Puzzle #8: RollApp Sequencer Challenge");

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 8);
    }
}
