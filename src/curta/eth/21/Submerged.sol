// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

contract Submerged is IPuzzle {
    TxHashSimulator public simulator = new TxHashSimulator();

    mapping (bytes32 => bool) public submergedTxs;
    mapping (bytes32 => bool) public submergedSeeds;

    function name() external pure returns (string memory) {
        return "Submerged";
    }

    function generate(address seed) external pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed)));
    }

    function verify(uint256 seed, uint256 solution) external view returns (bool) {
        return submergedSeeds[keccak256(abi.encode(seed, solution))];
    }

    function proveSubmergedTx() external {
        bytes32 txHash = simulator.TXHASH();
        require(txHash != bytes32(0), "must use TxHashSimulator");
        require(address(tx.origin).balance == 0, "not fully submerged");

        submergedTxs[txHash] = true;
    }

    function proveSubmergedSeed(bytes calldata rawTx) external {
        require(submergedTxs[keccak256(rawTx)], "tx not submerged");

        bytes calldata data = rawTx;
        uint256 off;
        (, off) = RLP.parseList(data);
        data = data[off:];

        data = RLP.skip(data); // nonce
        data = RLP.skip(data); // gasPrice
        data = RLP.skip(data); // gasLimit
        data = RLP.skip(data); // to
        data = RLP.skip(data); // value

        (data, ) = RLP.splitBytes(data); // extra the tx calldata
        bytes32 seed = bytes32(data[:32]);

        submergedSeeds[seed] = true;
    }
}

contract TxHashSimulator {
    // wen TSTORE
    bytes32 public TXHASH;

    function getCurrentTxHash() internal view returns (bytes32 txHash) {
        require(tx.origin == msg.sender, "can only verify txHash if sender is origin");

        // collect parameters
        // note: gasLimit could be derived from entry gas and calldata,
        //       but it's cheaper to require it in calldata
        uint256 gasLimit;
        bytes32 seed;
        assembly {
            seed := calldataload(0)
            gasLimit := calldataload(32)
        }

        uint8 v = 27;
        bytes32 r;
        bytes32 s;
        assembly {
            mstore(0, seed)
            r := keccak256(0, 32)
            mstore(0, r)
            s := keccak256(0, 32)
        }

        bytes[] memory txList = new bytes[](9);
        txList[0] = RLP.encodeUint(0); // nonce
        txList[1] = RLP.encodeUint(tx.gasprice); // gas price
        txList[2] = RLP.encodeUint(gasLimit); // claimed gasLimit
        txList[3] = RLP.encodeUint(uint256(uint160(address(this)))); // to address
        txList[4] = RLP.encodeUint(msg.value); // tx value
        txList[5] = RLP.encodeBytes(msg.data); // tx data
        txList[6] = RLP.encodeUint(uint256(v)); // v
        txList[7] = RLP.encodeUint(uint256(r)); // r
        txList[8] = RLP.encodeUint(uint256(s)); // s

        txHash = keccak256(RLP.encodeList(txList));

        // truncate the tx fields to exclude the signature data
        assembly {
            mstore(txList, 6)
        }

        bytes32 signingHash = keccak256(RLP.encodeList(txList));
        require(
            ecrecover(signingHash, v, r, s) == msg.sender,
            "could not verify tx hash"
        );
    }

    fallback() external {
        TXHASH = getCurrentTxHash();

        assembly {
            let target := calldataload(64)
            let len := sub(calldatasize(), 96)
            calldatacopy(0, 96, len)
            let res := call(
                gas(),
                target,
                callvalue(),
                0,
                len,
                0,
                0
            )
            sstore(TXHASH.slot, 0)
            if res {
                returndatacopy(0, 0, returndatasize())
                return(0, returndatasize())
            }
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }
}


library RLP {
    function parseUint(bytes calldata buf) internal pure returns (uint256 result, uint256 size) {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not a long string or list (> 0xB7)
            // also ensure it's not a short string longer than 32 bytes (> 0xA0)
            if gt(kind, 0xA0) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                result := kind
                size := 1
            }
            case false {
                // short string
                size := sub(kind, 0x80)

                // ensure it's not reading out of bounds
                if lt(buf.length, size) {
                    revert(0, 0)
                }

                switch eq(size, 32)
                case true {
                    // if it's exactly 32 bytes, read it from calldata
                    result := calldataload(add(buf.offset, 1))
                }
                case false {
                    // if it's < 32 bytes, we've already read it from calldata
                    result := shr(shl(3, sub(32, size)), shl(8, first32))
                }
                size := add(size, 1)
            }
        }
    }

    function nextSize(bytes calldata buf) internal pure returns (uint256 size) {
        assembly {
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            switch lt(kind, 0x80)
            case true {
                // small single byte
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    size := add(1, sub(kind, 0x80))
                }
                case false {
                    switch lt(kind, 0xC0)
                    case true {
                        // long string
                        let lengthSize := sub(kind, 0xB7)

                        // ensure that we don't overflow
                        if gt(lengthSize, 31) {
                            revert(0, 0)
                        }

                        // ensure that we don't read out of bounds
                        if lt(buf.length, lengthSize) {
                            revert(0, 0)
                        }
                        size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                        size := add(size, add(1, lengthSize))
                    }
                    case false {
                        switch lt(kind, 0xF8)
                        case true {
                            // short list
                            size := add(1, sub(kind, 0xC0))
                        }
                        case false {
                            let lengthSize := sub(kind, 0xF7)

                            // ensure that we don't overflow
                            if gt(lengthSize, 31) {
                                revert(0, 0)
                            }
                            // ensure that we don't read out of bounds
                            if lt(buf.length, lengthSize) {
                                revert(0, 0)
                            }
                            size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                            size := add(size, add(1, lengthSize))
                        }
                    }
                }
            }
        }
    }

    function skip(bytes calldata buf) internal pure returns (bytes calldata) {
        uint256 size = RLP.nextSize(buf);
        assembly {
            buf.offset := add(buf.offset, size)
            buf.length := sub(buf.length, size)
        }
        return buf;
    }

    function parseList(bytes calldata buf)
        internal
        pure
        returns (uint256 listSize, uint256 offset)
    {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a list
            if lt(kind, 0xC0) {
                revert(0, 0)
            }

            switch lt(kind, 0xF8)
            case true {
                // short list
                listSize := sub(kind, 0xC0)
                offset := 1
            }
            case false {
                // long list
                let lengthSize := sub(kind, 0xF7)

                // ensure that we don't overflow
                if gt(lengthSize, 31) {
                    revert(0, 0)
                }
                // ensure that we don't read out of bounds
                if lt(buf.length, lengthSize) {
                    revert(0, 0)
                }
                listSize := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                offset := add(lengthSize, 1)
            }
        }
    }

    function splitBytes(bytes calldata buf)
        internal
        pure
        returns (bytes calldata result, bytes calldata rest)
    {
        uint256 offset;
        uint256 size;
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not list
            if gt(kind, 0xBF) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                offset := 0
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    offset := 1
                    size := sub(kind, 0x80)
                }
                case false {
                    // long string
                    let lengthSize := sub(kind, 0xB7)

                    // ensure that we don't overflow
                    if gt(lengthSize, 31) {
                        revert(0, 0)
                    }
                    // ensure we don't read out of bounds
                    if lt(buf.length, lengthSize) {
                        revert(0, 0)
                    }
                    size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                    offset := add(lengthSize, 1)
                }
            }

            result.offset := add(buf.offset, offset)
            result.length := size

            let end := add(offset, size)
            rest.offset := add(buf.offset, end)
            rest.length := sub(buf.length, end)
        }
    }

    function encodeLength(uint256 len, uint8 offset) internal pure returns (bytes memory result) {
        if (len < 56) {
            result = new bytes(1);
                assembly {
                    mstore(
                        add(result, 32),
                        shl(248, add(offset, len))
                    )
                }
        } else {
            require(len < 2**32, "lengths exceeding UINT32_MAX are unsupported");
            if (len > 2**24) {
                result = new bytes(5);
                assembly {
                    mstore(
                        add(result, 32),
                        or(
                            shl(248, add(offset, 59)),
                            shl(216, len)
                        )
                    )
                }
            } else if (len > 2**16) {
                result = new bytes(4);
                assembly {
                    mstore(
                        add(result, 32),
                        or(
                            shl(248, add(offset, 58)),
                            shl(224, len)
                        )
                    )
                }
            } else if (len > 2**8) {
                result = new bytes(3);
                assembly {
                    mstore(
                        add(result, 32),
                        or(
                            shl(248, add(offset, 57)),
                            shl(232, len)
                        )
                    )
                }
            } else {
                result = new bytes(2);
                assembly {
                    mstore(
                        add(result, 32),
                        or(
                            shl(248, add(offset, 56)),
                            shl(240, len)
                        )
                    )
                }
            }
        }
    }

    function encodeList(bytes[] memory encodedElems) internal view returns (bytes memory result) {
        uint256 totalLength;
        assembly {
            let elemsStart := add(encodedElems, 0x20)
            let elemsEnd := add(elemsStart, mul(0x20, mload(encodedElems)))
            for {let off := elemsStart} lt(off, elemsEnd) {off := add(off, 0x20)} {
                let elem := mload(off)
                totalLength := add(totalLength, mload(elem))
            }
        }
        bytes memory encodedLength = encodeLength(totalLength, 0xc0);
        unchecked { totalLength += encodedLength.length; }
        result = new bytes(totalLength);
        assembly {
            let ptr := add(result, 0x20)
            mstore(ptr, mload(add(encodedLength, 0x20)))
            ptr := add(ptr, mload(encodedLength))

            let elemsStart := add(encodedElems, 0x20)
            let elemsEnd := add(elemsStart, mul(0x20, mload(encodedElems)))
            for {let off := elemsStart} lt(off, elemsEnd) {off := add(off, 0x20)} {
                let elem := mload(off)
                let len := mload(elem)
                if iszero(staticcall(
                    gas(),
                    4,
                    add(elem, 0x20),
                    len,
                    ptr,
                    len
                )) {
                    revert(0, 0)
                }
                ptr := add(ptr, len)
            }
        }
    }


    function encodeBytes(bytes memory elem) internal pure returns (bytes memory) {
        return abi.encodePacked(
            encodeLength(elem.length, 0x80),
            elem
        );
    }

    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        // allocate our result bytes
        bytes memory result = new bytes(33);

        if (value == 0) {
            // store length = 1, value = 0x80
            assembly {
                mstore(add(result, 1), 0x180)
            }
            return result;
        }

        if (value < 128) {
            // store length = 1, value = value
            assembly {
                mstore(add(result, 1), or(0x100, value))
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 33, prefix 0xa0 followed by value
            assembly {
                mstore(add(result, 1), 0x21a0)
                mstore(add(result, 33), value)
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 32, prefix 0x9f followed by value
            assembly {
                mstore(add(result, 1), 0x209f)
                mstore(add(result, 33), shl(8, value))
            }
            return result;
        }

        assembly {
            let length := 1
            for {
                let min := 0x100
            } lt(sub(min, 1), value) {
                min := shl(8, min)
            } {
                length := add(length, 1)
            }

            let bytesLength := add(length, 1)

            // bytes length field
            let hi := shl(mul(bytesLength, 8), bytesLength)

            // rlp encoding of value
            let lo := or(shl(mul(length, 8), add(length, 0x80)), value)

            mstore(add(result, bytesLength), or(hi, lo))
        }
        return result;
    }
}
