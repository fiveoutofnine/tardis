// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {AuthorshipToken} from "curta/AuthorshipToken.sol";
import {Curta} from "curta/Curta.sol";
import {FlagRenderer} from "@/contracts/FlagRenderer.sol";
import {IPuzzle} from "curta/interfaces/IPuzzle.sol";
import {MockPuzzle} from "curta/utils/mock/MockPuzzle.sol";
import {LibRLP} from "curta/utils/LibRLP.sol";

/// @notice A solution setup contract for Curta. In `setUp`, it deploys an
/// instance of Curta contracts, labels addresses, and has a helper function to
/// deploy and add mock puzzles to Curta to skip to a given puzzle ID.
abstract contract CurtaSolution is Test {
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

    /// @notice Sets addresses, labels addresses, and sets the environment
    /// variables.
    constructor(uint256 _chainId) {
        // Set addresses.
        mockAuthor = makeAddr("mockAuthor");
        owner = makeAddr("owner");
        // Label addresses.
        vm.label(mockAuthor, "Mock author");
        vm.label(owner, "Owner");
        // Set environment variables.
        chainId = _chainId;
    }

    /// @notice Deploys an instance of the Curta contracts and labels them.
    function setUp() public {
        // Transaction #1.
        flagRenderer = new FlagRenderer();
        vm.label(address(flagRenderer), "`FlagRenderer`");

        // Curta will be deployed on transaction #3.
        address curtaAddress = LibRLP.computeAddress(address(this), 3);

        // Transaction #2.
        address[] memory authors = new address[](0);
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

        // Finally, set the environment variables in the VM.
        vm.chainId(chainId);
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Deploys and adds `_id - 1` instances of `mockPuzzle` as puzzles
    /// to Curta to skip to that ID.
    /// @param _id The ID of the puzzle to skip to.
    function _skipToPuzzleId(uint32 _id) internal {
        // Return early if `_id` is 0.
        if (_id == 0) return;

        // Deploy and add `_id - 1` instances of `mockPuzzle`.
        unchecked {
            uint256 count = _id - 1;
            for (uint256 i; i < count; ++i) {
                // Mint an Authorship Token to the mock author.
                vm.prank(address(curta));
                authorshipToken.curtaMint(mockAuthor);

                // Add the puzzle to Curta.
                vm.prank(mockAuthor);
                curta.addPuzzle(IPuzzle(mockPuzzle), i);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Interface
    // -------------------------------------------------------------------------

    /// @notice Test function for players to implement their solution.
    function test_solve() public virtual;
}
