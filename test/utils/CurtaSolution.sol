// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {AuthorshipToken} from "curta/AuthorshipToken.sol";
import {Curta} from "curta/Curta.sol";
import {FlagRenderer} from "@/contracts/FlagRenderer.sol";
import {IPuzzle} from "curta/interfaces/IPuzzle.sol";
import {MockPuzzle} from "curta/utils/mock/MockPuzzle.sol";
import {LibRLP} from "curta/utils/LibRLP.sol";

/// @notice A solution set-up contract for Curta. In `setUp`, it deploys an
/// instance of Curta contracts, labels addresses, adds mock puzzles to Curta to
/// skip to a given puzzle ID (note: an extra authorship token is minted to
/// `mockAuthor` for each puzzle's set-up contract to be able to add the
/// puzzle).
abstract contract CurtaSolution is Test {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when the solver's address is invalid.
    error InvalidSolverAddress();

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice ID of the environment's chain.
    uint256 internal immutable chainId;

    /// @notice Address of the mock author used to add puzzles to skip to a
    /// given puzzle ID.
    address internal immutable mockAuthor;

    /// @notice Address of the owner of the contracts.
    address internal immutable owner;

    /// @notice ID of the puzzle to solve.
    uint32 internal immutable puzzleId;

    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The Authorship Token contract.
    AuthorshipToken internal authorshipToken;

    /// @notice The Curta contract.
    Curta internal curta;

    /// @notice The Flag metadata and art renderer contract.
    FlagRenderer internal flagRenderer;

    /// @notice A mock puzzle contract.
    MockPuzzle internal mockPuzzle;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Sets addresses, labels addresses, and sets remaining variables.
    /// @dev Both `_chainId` and `_puzzleId` must be greater than 0.
    /// @param _chainId ID of the environment's chain.
    /// @param _puzzleId ID of the puzzle to solve.
    constructor(uint256 _chainId, uint32 _puzzleId) {
        // Require `_chainId` and `_puzzleId` to be greater than 0.
        require(_chainId > 0 && _puzzleId > 0);

        // Set addresses.
        mockAuthor = makeAddr("mockAuthor");
        owner = makeAddr("owner");
        // Label addresses.
        vm.label(mockAuthor, "Mock author");
        vm.label(owner, "Owner");
        // Set variables.
        chainId = _chainId;
        puzzleId = _puzzleId;
    }

    /// @notice Deploys an instance of the Curta contracts and labels them.
    function setUp() public virtual {
        // Transaction #1.
        flagRenderer = new FlagRenderer();
        vm.label(address(flagRenderer), "`FlagRenderer`");

        // Curta will be deployed on transaction #3.
        address curtaAddress = LibRLP.computeAddress(address(this), 3);

        // Transaction #2.
        address[] memory authors = new address[](1);
        authors[0] = mockAuthor;
        authorshipToken = new AuthorshipToken({
            _curta: curtaAddress,
            _issueLength: 3 days,
            _authors: authors
        });
        vm.label(address(authorshipToken), "`AuthorshipToken`");

        // Transaction #3.
        curta = new Curta(authorshipToken, flagRenderer);
        vm.label(address(curta), "`Curta`");

        // Transaction #4.
        mockPuzzle = new MockPuzzle();
        vm.label(address(mockPuzzle), "`MockPuzzle`");

        // Transfer ownership of the contracts to their respective owners.
        authorshipToken.transferOwnership(owner);
        curta.transferOwnership(owner);

        // Set the environment variables in the VM.
        vm.chainId(chainId);

        // Finally, skip to the puzzle ID by adding `_id - 1` instances of
        // `mockPuzzle` as `mockAuthor` to `curta`.
        unchecked {
            uint256 count = puzzleId - 1;
            for (uint256 i; i < count; ++i) {
                // Mint an Authorship Token to `mockAuthor`.
                vm.prank(address(curta));
                authorshipToken.curtaMint(mockAuthor);

                // Add the puzzle to Curta as `mockAuthor`.
                vm.prank(mockAuthor);
                curta.addPuzzle(IPuzzle(mockPuzzle), i);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    /// @notice Validates if some address is a valid solver: i.e., not the zero
    /// address, a precompile, the `owner`, the `mockAuthor`, or equal to any of
    /// the contracts'.
    /// @param _solver Address to validate.
    function _validateSolver(address _solver) internal view {
        // Validate `_solver`.
        if (
            uint160(_solver) <= 0x10 ||
            _solver == owner ||
            _solver == mockAuthor ||
            _solver == address(authorshipToken) ||
            _solver == address(curta) ||
            _solver == address(flagRenderer) ||
            _solver == address(mockPuzzle)
        ) {
            revert InvalidSolverAddress();
        }
    }

    // -------------------------------------------------------------------------
    // Interface
    // -------------------------------------------------------------------------

    /// @notice Test function for players to implement their solution.
    function test_solve() public virtual;
}
