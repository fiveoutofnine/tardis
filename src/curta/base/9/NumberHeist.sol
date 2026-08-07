// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

//
//
//    888b    888                        888                            888    888          d8b          888
//    8888b   888                        888                            888    888          Y8P          888
//    88888b  888                        888                            888    888                       888
//    888Y88b 888 888  888 88888b.d88b.  88888b.   .d88b.  888d888      8888888888  .d88b.  888 .d8888b  888888
//    888 Y88b888 888  888 888 "888 "88b 888 "88b d8P  Y8b 888P"        888    888 d8P  Y8b 888 88K      888
//    888  Y88888 888  888 888  888  888 888  888 88888888 888          888    888 88888888 888 "Y8888b. 888
//    888   Y8888 Y88b 888 888  888  888 888 d88P Y8b.     888          888    888 Y8b.     888      X88 Y88b.
//    888    Y888  "Y88888 888  888  888 88888P"   "Y8888  888          888    888  "Y8888  888  88888P'  "Y888
//
//
//       ||====================================================================||
//       ||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||
//       ||(100)==================| POINTS RESERVE NOTE |=================(100)||
//       ||\\$//        ~         '------========-------'                 \\$//||
//       ||<< /        /$\              // ____ \\                         \ >>||
//       ||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||
//       ||<<|        \\ //           || <||  >\  ||                        |>>||
//       ||>>|         \$/            ||  $$ --/  ||      One Hundred Pts   |<<||
//    ||====================================================================||>||
//    ||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||<||
//    ||(100)==================| POINTS RESERVE NOTE |=================(100)||>||
//    ||\\$//        ~         '------========-------'                 \\$//||\||
//    ||<< /        /$\              // ____ \\                         \ >>||)||
//    ||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||/||
//    ||<<|        \\ //           || <||  >\  ||                        |>>||=||
//    ||>>|         \$/            ||  $$ --/  ||      One Hundred Pts   |<<||
//    ||<<|      L38036133B        *\\  |\_/  //* series                 |>>||
//    ||>>|  12                     *\\/___\_//*   1989                  |<<||
//    ||<<\      Treasurer    ____/Blast Franklin\_____     Secretary 12 />>||
//    ||//$\                  ~| FEDERATION OF POINTS |~                /$\\||
//    ||(100)==================   ONE HUNDRED POINTS  =================(100)||
//    ||\\$//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\$//||
//    ||====================================================================||
//
//
// @dev You are <REDACTED>, the infamous digital points thief, renowned for
// dozens of successful heists totaling 513,450,000,000 in stolen points.
//
// You have been hired by a mysterious benefactor to steal from a safe, your usual gig.
//
// Only this safe is not locked with a key, but with a number.
// You must find a number which defies the laws of mathematics itself.
//
// This number is both a prime and composite number at the same time...
//
// If you're able to do that, legend has it that the safe contains a treasure worth more than
// all your precious little points combined... a Curta Flag NFT!
contract NumberHeist is IPuzzle {

    bytes32 constant VALID_FACTORIALS_HASH = 0x024260b3e934c04b47e60ebbf3a5974c8008d1494ac24bfb1358daf47e752953;
    uint256 constant SOLUTION = 0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a28; // Not so easy...

    modifier restoreMemory() {
        _;
        assembly {
            mstore(0x40, 0x80) // NooOoOOoooOooOoooOOOoooOOooOoOoooOOOoooOoOOo my memory...
        }
    }

    mapping(address => bool) public solved;

    function name() external pure returns (string memory) {
        return "NumberHeist";
    }

    function generate(address _seed) external pure returns (uint256 ret) {
        assembly {
            ret := _seed
        }
    }

    function verify(uint256 _start, uint256 _solution) external view returns (bool) {
        require(_solution == SOLUTION);
        return solved[address(uint160(_start))];
    }

    // The safe is locked with three layers of security against such tampering.
    // However, it's nothing you haven't dealt with before.
    // Begin the heist!
    function heist(uint256 n, uint256 circleCuttingWitness, uint256 factor1, uint256 factor2) external returns (bool heistSuccess) {
        require(1 < n && n <= 32);
        require(factor1 > 1 && factor2 > 1);
        require(factor1 < n && factor2 < n);

        bytes memory magicTome = _initializePuzzle();

        // ---- Check Prime By Wilson's ----
        if (!_checkWilsons(n)) {
            return false;
        }

        // ---- Check Prime By Circle Cutting ----
        if (!_isPrimeByCircleCutting(magicTome, n, circleCuttingWitness)) {
            return false;
        }

        // ---- Check Not Composite By Filson's ----
        if (!_filsonsCompositenessCheck(n)) {
            return false;
        }

        // This number has passed 3 layers of prime security checks...
        // But will it defy the laws of mathematics?
        if(n == factor1 * factor2) {
            solved[msg.sender] = true;
            heistSuccess = true;
        }
    }


    //////////////////////////////////////////////////////////////////////////////////////
    /// WILSON'S
    //////////////////////////////////////////////////////////////////////////////////////

    // We will use the famous result from Wilson's Theorem to test for primality:
    //
    //  (n-1)! ≡ -1 (mod n) <=> n is prime
    function _checkWilsons(uint256 n) internal restoreMemory returns (bool) {
        // Caller provides the precomputed factorials... because why not?
        // Largest factorial necessary for wilson's is (n-1)!, therefore we need 0!..31!

        // Three entries: [ x! ∀ x <= 12, x! ∀ 12 < x <= 20, x! ∀ 20 < x <= 31 ]
        // First entry factorials fit into 4 byte denominations
        // Second entry factorials fit into 8 byte denominations
        // Third entry factorials fit into 16 byte denominations
        (bool success, bytes memory data) = msg.sender.call("");
        require(success);

        // Nothing to see here...
        assembly {
            mstore(0x40, 0x360)
        }

        bytes[3] memory precomputedFactorials = abi.decode(data, (bytes[3]));

        // hash the precomputedFactorials to ensure they are correct
        require(keccak256(abi.encodePacked(precomputedFactorials[0], precomputedFactorials[1], precomputedFactorials[2])) == VALID_FACTORIALS_HASH, "Not Valid Factorials");

        // Declare Pointers
        bytes memory f0 = precomputedFactorials[0];
        bytes memory f1 = precomputedFactorials[1];
        bytes memory f2 = precomputedFactorials[2];

        uint256 modResult;

        // Verify Wilson's
        assembly {
            let nMinusOneFactorial

            if lt(n, 14) {
                let factorialsStart := add(f0, 0x08)
                let factorialSpot := mload(add(factorialsStart, mul(sub(n, 1), 0x08)))
                nMinusOneFactorial := and(factorialSpot, 0xFFFFFFFFFFFFFFFF)
            }
            if and(gt(n, 13), lt(n, 22)) {
                let factorialsStart := add(f1, 0x0c)
                let factorialSpot := mload(add(factorialsStart, mul(sub(n, 14), 0x0c)))
                nMinusOneFactorial := and(factorialSpot, 0xFFFFFFFFFFFFFFFFFFFFFFFF)
            }
            if gt(n, 21) {
                let factorialsStart := add(f2, 0x10)
                let factorialSpot := mload(add(factorialsStart, mul(sub(n, 22), 0x10)))
                nMinusOneFactorial := and(factorialSpot, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            }

            modResult := addmod(nMinusOneFactorial, 1, n)
        }

        return modResult == 0;
    }


    //////////////////////////////////////////////////////////////////////////////////////
    /// CIRCLE CUTTING
    //////////////////////////////////////////////////////////////////////////////////////

    function _initializePuzzle() internal pure returns (bytes memory magicTome) {
        // What could this be?
        assembly {
            magicTome := 0x760
            let tomePtr := add(magicTome, 0x20)
            let tomeSize := 0x100
            mstore(
                tomePtr,
                hex"0000000000000007000000000000000500000000000000150000000000000011"
            )
            mstore(
                add(tomePtr, 0x20),
                hex"0000000000000155000000000000001d00000000000015550000000000000101"
            )
            mstore(
                add(tomePtr, 0x40),
                hex"000000000000104100000000000001dd00000000001555550000000000000131"
            )
            mstore(
                add(tomePtr, 0x60),
                hex"00000000015555550000000000001ddd000000000001c74d0000000000010001"
            )
            mstore(
                add(tomePtr, 0x80),
                hex"000000015555555500000000000010c100000015555555550000000000013131"
            )
            mstore(
                add(tomePtr, 0xA0),
                hex"0000000001C7134D00000000001DDDDD00001555555555550000000000010301"
            )
            mstore(
                add(tomePtr, 0xC0),
                hex"00000100401004010000000001DDDDDD00000010000400010000000001313131"
            )
            mstore(
                add(tomePtr, 0xE0),
                hex"01555555555555550000000000014FC515555555555555550000000000000000"
            )
            mstore(magicTome, tomeSize)
        }
    }

    // cyclo-
    // ˈsīklō - Greek
    //      1. circular
    //      2. relating to a circle
    //
    // tomic
    // ˈtɑmɪk - Greek
    //      1. of or relating to cutting, division, sections, etc.
    //
    // Let Φ𝑛 be the nth cyclotomic polynomial, then we propose ∃ 𝑎 s.t.:
    //
    //      𝑝 is prime <=> Φ𝑝−1(𝑎) ≡ 0 (mod 𝑝)
    //
    // Can this be true...?
    function _isPrimeByCircleCutting(bytes memory cyclotomics, uint256 n, uint256 witness) internal returns (bool) {
        if (cyclotomics.length != 0x100) {
            revert("Invalid cyclotomics length");
        }
        // Get the right cyclotomic from the magic tome
        bytes8 cyclotomic = _readCyclotomic(cyclotomics, n-1);
        int256 result = _evaluateCyclotomic(cyclotomic, witness);

        return result % int256(n) == 0;
    }

    function _readCyclotomic(bytes memory cyclotomics, uint256 n) internal pure returns (bytes8 cyclotomic) {
        assembly {
            let cyclo_size := 0x08
            cyclotomic := and(mload(add(add(cyclotomics, 0x20), mul(sub(n, 1), cyclo_size))), 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000)
        }
    }

    function _evaluateCyclotomic(bytes8 cyclotomic, uint256 x) internal returns (int256 res) {
        for (uint256 i = 63; i > 1; i-=2) {
            uint8 cycloByte = uint8(cyclotomic[i / 8]);

            uint adjustment = (7 - (i % 8));

            uint8 sign = uint8(cycloByte & (1 << (adjustment + 1)));
            uint8 bit = uint8(cycloByte & (1 << adjustment));

            if (bit != 0) {
                int256 val = int256(x**((63-i)/2));
                if (sign != 0) {
                    res -= val;
                } else if (sign == 0){
                    res += val;
                } else {
                    revert("Invalid sign");
                }
            }
        }
    }


    //////////////////////////////////////////////////////////////////////////////////////
    /// FILSON'S
    //////////////////////////////////////////////////////////////////////////////////////

    // As a corollary to Wilson's we derive Filson's:
    //
    //  (n-1)! ≡ 0 (mod n) <=> n is composite
    //
    // This interesting result is based on the following observation when n is composite:
    //
    //  ∃ x0, x1 ∈ {1,2,..n-1} s.t. x0 * x1 = a * n for some a ∈ Zn+
    //
    // Proving this is left as an exercise for the reader...
    function _filsonsCompositenessCheck(uint256 n) internal pure returns (bool) {
        return factorial(n-1) % n != 0;
    }

    // Use an independent method to compute factorials for Filson's,
    // just in case the pre-computed method is vulnerable ;)
    function factorial(uint n) public pure returns (uint) {
        if (n == 0) {
            return 1;
        }
        uint result = 1;
        for (uint i = 1; i <= n; i++) {
            result *= i;
        }
        return result;
    }

}
