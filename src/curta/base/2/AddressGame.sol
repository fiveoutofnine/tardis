// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

interface IBox {
    function isSolved() external view returns (bool);
}

contract AddressGame is IPuzzle {
    uint256 public number;
    function name() external pure returns (string memory) {
        return "AddressGame";
    }

    function generate(address x) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(x)));
    }

    function verify(uint256 seed, uint256 solution) external returns (bool) {
        uint256[16] memory c;
        for (uint256 i = 0; i < 40; i++) {
            uint256 step = (solution >> (i * 4)) & 0xf;
            c[step] += 1;
        }

        {
            require(((c[0xa] + c[0xe]) & 1) == box(seed, 0) % 2, "#vowels");
            require(
                ((c[0xb] + c[0xc] + c[0xd] + c[0xf]) % 3) == box(seed, 1) % 3,
                "#consonant"
            );
        }

        {
            uint256 _sum = 0;
            for (uint256 i = 1; i < 10; i++) {
                _sum += c[i] * i;
            }
            require(_sum == 25 + (seed % 50));
        }

        return IBox(address(uint160(solution))).isSolved();
    }

    function box(uint256 seed, uint256 anything) public pure returns (uint256) {
        unchecked {
            return
                (0x123456789 * seed + 17879862832311687437 * anything) %
                (15203777108537674021);
        }
    }
}
