// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {TwoTimesFourIsEight} from "src/curta/eth/1/CurtaEth1.sol";
import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(1, 1) {
    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The puzzle contract.
    IPuzzle internal puzzle;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Deploys, labels, and adds the puzzle to the Curta contract.
    function setUp() public virtual override {
        super.setUp();

        // Deploy and label the puzzle contract.
        puzzle = IPuzzle(new TwoTimesFourIsEight());
        vm.label(address(puzzle), string.concat("Puzzle #1: ", puzzle.name()));

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 1);
    }
}
