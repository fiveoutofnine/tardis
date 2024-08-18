// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

import "./memmove/Mapping.sol";
import "./solvm/Evm.sol";

struct Solution {
    uint8 stop;
    uint8 ctxSetting;
    bytes code;
}

contract MiniMutant is IPuzzle {
    using EvmLib for Evm;
    using MappingLib for Mapping;

    function name() external pure returns (string memory) {
        return "Mini Mutant";
    }

    function generate(address _seed) external returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed)));
    }

    function verify(uint256 _start, uint256 _solution) external returns (bool) {
        Solution memory sol = Solution({
            stop: 0,
            ctxSetting: 0,
            code: abi.encodePacked(_solution)
        });

        address origin = tx.origin;
        address caller = msg.sender;
        address execution_address = address(this);
        bytes memory calld = abi.encodePacked(_start);

        while (sol.stop == 0) {
            if (sol.ctxSetting == 0) {
                origin = tx.origin;
                caller = msg.sender;
                execution_address = address(this);
            } else if (sol.ctxSetting == 1) {
                origin = msg.sender;
                caller = address(this);
            }

            (bool succ, bytes memory ret) = this.run(
                origin,
                caller,
                execution_address,
                calld,
                sol.code
            );
            require(succ, "Script failed");
            require(ret.length > 2, "Bad return length");
            sol.stop = uint8(ret[0]);
            sol.ctxSetting = uint8(ret[1]);
            sol.code = slice(ret, 2, ret.length - 2);
        }

        (bool succ, bytes memory ret) = this.run(
            origin,
            caller,
            execution_address,
            calld,
            sol.code
        );
        require(succ, "Script failed");
        uint256 result = abi.decode(ret, (uint256));
        require(result == _start, "Fail");
        return true;
    }

    function run(
        address origin,
        address caller,
        address execution_address,
        bytes calldata calld,
        bytes calldata executionCode
    ) external returns (bool, bytes memory) {
        uint256 fee;
        uint256 id;
        assembly ("memory-safe") {
            fee := basefee()
            id := chainid()
        }
        EvmContext memory ctx = EvmContext({
            origin: origin,
            caller: caller,
            execution_address: execution_address,
            callvalue: 0,
            coinbase: block.coinbase,
            timestamp: block.timestamp,
            number: block.number,
            gaslimit: block.gaslimit,
            difficulty: block.difficulty,
            chainid: id,
            basefee: fee,
            balances: MappingLib.newMapping(1),
            calld: calld
        });
        Evm evm = EvmLib.newEvm(ctx);

        // NOTE: No frame switching opcodes are supported (i.e. Call, Create, etc.)
        return evm.evaluate(executionCode);
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}
