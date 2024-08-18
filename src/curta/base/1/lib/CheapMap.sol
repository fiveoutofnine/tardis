// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Creator.sol";
import "./Bytecode.sol";

library CheapMap {
  //                                         keccak256(bytes('CheapMap.slot'))
  bytes32 private constant SLOT_KEY_PREFIX = 0x06fccbac10f612a9037c3e903b4f4bd03ffbc103781cbe821d25b33299e50efb;

  function internalKey(bytes32 _key) internal pure returns (bytes32) {
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
  }

  function write(string memory _key, bytes memory _data) internal returns (address pointer) {
    return write(keccak256(bytes(_key)), _data);
  }

  function write(bytes32 _key, bytes memory _data) internal returns (address pointer) {
    bytes memory code = Bytecode.creationCodeFor(_data);
    pointer = Creator.create(internalKey(_key), code);
  }

  function read(string memory _key) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)));
  }

  function read(string memory _key, uint256 _start) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start);
  }

  function read(string memory _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start, _end);
  }

  function read(bytes32 _key) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), 0, type(uint256).max);
  }

  function read(bytes32 _key, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), _start, type(uint256).max);
  }

  function read(bytes32 _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(Creator.addressOf(internalKey(_key)), _start, _end);
  }
}
