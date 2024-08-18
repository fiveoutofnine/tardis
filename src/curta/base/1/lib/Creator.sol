//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Creator {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();

  bytes internal constant PROXY_CHILD_BYTECODE = hex"68_36_3d_3d_37_36_3d_34_f0_ff_3d_52_60_09_60_17_f3_ff";
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x648b59bcbb41c37892d3b820522dc8b8c275316bb020f043a9068f607abeb810;

  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  function create(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    return create(_salt, _creationCode, 0);
  }

  function create(bytes32 _salt, bytes memory _creationCode, uint256 _value) internal returns (address addr) {
    bytes memory creationCode = PROXY_CHILD_BYTECODE;
    addr = addressOf(_salt);
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();
    (bool success,) = proxy.call{ value: _value }(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }
}
