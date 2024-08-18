// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Setup} from "./Setup.sol";

/// @dev View the puzzle's source at `src/curta/example/1`.
contract Solution is Setup(0xA85572Cd96f1643458f17340b6f0D6549Af482F5) {
    function test_solve() public virtual override {
        uint256 solution = uint256(uint160(solver));

        vm.prank(solver);
        curta.solve({_puzzleId: puzzleId, _solution: solution});
    }
}
