// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {BillyTheBull} from "src/curta/eth/15/BillyTheBull.sol";
import {NFTOutlet} from "src/curta/eth/15/NFTOutlet.sol";
import {RippedJesus} from "src/curta/eth/15/tokens/RippedJesus.sol";

import {CurtaSolution} from "test/utils/CurtaSolution.sol";

abstract contract Setup is CurtaSolution(1, 15) {
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

        // Deploy the assets, outlet, and puzzle.
        vm.prank(mockAuthor, mockAuthor);
        BillyTheBull billy = new BillyTheBull();
        MockERC20 paymentToken = new MockERC20("Dai Stablecoin", "DAI", 18);
        RippedJesus nft = new RippedJesus();

        address[] memory paymentTokens = new address[](1);
        paymentTokens[0] = address(paymentToken);
        address[] memory nfts = new address[](1);
        nfts[0] = address(nft);

        NFTOutlet outlet = new NFTOutlet(address(billy), paymentTokens, nfts);
        nft.initialize(address(outlet));
        billy.initialize(address(outlet), 1_000 ether);

        // Label the puzzle contract.
        puzzle = IPuzzle(address(billy));
        vm.label(address(puzzle), "Puzzle #15: Billy the Bull");

        // Add puzzle to Curta as `mockAuthor`.
        vm.prank(mockAuthor);
        curta.addPuzzle(puzzle, 15);
    }
}
