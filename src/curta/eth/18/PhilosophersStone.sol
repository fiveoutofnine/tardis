// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IPuzzle } from "curta/interfaces/IPuzzle.sol";
import { LibClone } from "solady/utils/LibClone.sol";

/**
 *                              ☉☉☉   ♄ 🝡🝟 ☉   ☉☉☉
 *                           ☉♄         ♄          ☉♄
 *                       ☉♄             🝡              ☉♄
 *                    ☉♄              ♄   ♄               ☉♄
 *                  ☉♄               🝡      🝡               ☉♄
 *                ☉♄                ♄        ♄               ☉♄
 *               ☉♄               ☉           ☉               ☉♄
 *              ☉♄               ♄              ♄              ☉♄
 *             ☉♄              ☉ ♄ ♄ ♄ ♄ ♄ ♄ ♄ ♄ ☉             ☉♄
 *             ☉♄            ♄ ♄     🝡🝡☉🝟☉🝡🝡     ♄ ♄            ☉♄
 *             ☉♄          ☉   ♄   🝡☉        ☉🝡  ♄  ☉           ☉♄
 *             ☉♄         ♄    ♄ 🝡☉           ☉🝡 ♄    ♄         ☉♄
 *             ☉♄       🝡      ♄ 🝡☉           ☉🝡 ♄      🝡       ☉♄
 *              ☉♄    ♄        ♄   🝡☉       ☉🝡   ♄        ♄    ☉♄
 *               ☉♄ ♄          ♄     🝡🝡☉🝟☉🝡🝡     ♄          ♄ ☉♄
 *                ☉🝡 ♄ ♄ ♄ ♄ ♄ ☉ ♄ ♄ ♄ ♄ ♄ ♄ ♄ ♄ ☉ ♄ ♄ ♄ ♄ ♄ 🝡☉
 *                  ☉♄                                      ☉♄
 *                    ☉♄                                  ☉♄
 *                       ☉♄                            ☉♄
 *                           ☉♄                    ☉♄
 *                              ☉☉☉   ♄ 🝡🝟 ☉   ☉☉☉
 *
 * @title ♄ 🝡🝟 ☉
 *
 * @notice "The World hath been much abused by the Opinion of Making of Gold:
 *          The Worke it selfe I judge to be possible; But the Meanes to effect
 *          it, are, in the Practice, full of Errour and Imposture; And in the
 *          Theory, full of unsound Imaginations."
 *
 *         - Francis Bacon, 1627
 *
 * @author horsefacts.eth <horsefacts@terminally.online>
 */
contract PhilosophersStone is IPuzzle {
  using LibClone for address;

  struct Trial {
    uint32 aeon;
    address arcanum;
    uint8 phase;
  }

  address codex;
  mapping(uint256 => Trial) trials;
  mapping(address => bool) elixirs;

  constructor() {
    codex = address(new Codex());
    codex.call(
      abi.encodeWithSignature(
        "prepare(address,address,bytes4)", address(0), address(0), bytes4(0)
      )
    );
  }

  function name() external pure returns (string memory) {
    return unicode"♄ 🝡🝟 ☉";
  }

  function generate(address _seed) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(_seed)));
  }

  function verify(uint256 _start, uint256 _solution) external view returns (bool) {
    Trial memory trial = trials[_start];
    require(trial.arcanum == address(uint160(_solution)));
    return trial.phase == 2;
  }

  function alter(address adept) public {
    require(elixirs[msg.sender]);
    elixirs[msg.sender] = false;
    uint256 sigil = generate(adept);
    trials[sigil].phase += 1;
  }

  function transmute(uint256 materia) external {
    uint256 sigil = generate(msg.sender);
    trials[sigil] = Trial({
      aeon: uint32(block.number),
      arcanum: address(uint160(materia)),
      phase: 0
    });
  }

  function solve() external {
    uint256 sigil = generate(msg.sender);
    Trial memory trial = trials[sigil];

    require(trial.aeon == uint32(block.number));
    require(trial.phase == 0);

    address materia = trial.arcanum;
    require(bytes3(materia.codehash) == 0x001ead);

    bytes32 salt = bytes32(abi.encodePacked(uint128(trial.aeon), uint128(sigil)));
    bytes4 essence = bytes4(bytes32(sigil));

    address elixir = codex.cloneDeterministic(salt);
    elixir.call(
      abi.encodeWithSignature(
        "prepare(address,address,bytes4)", msg.sender, materia, essence
      )
    );
    elixirs[elixir] = true;
  }

  function coagula() external {
    uint256 sigil = generate(msg.sender);
    Trial memory trial = trials[sigil];

    require(trial.aeon == uint32(block.number));
    require(trial.phase == 1);

    address materia = trial.arcanum;
    require(bytes3(materia.codehash) == 0x00901d);

    bytes32 salt = bytes32(abi.encodePacked(uint128(trial.aeon), uint128(sigil >> 128)));
    bytes4 essence = bytes4(bytes32(sigil) << 32);

    address elixir = codex.cloneDeterministic(salt);
    elixir.call(
      abi.encodeWithSignature(
        "prepare(address,address,bytes4)", msg.sender, materia, essence
      )
    );
    elixirs[elixir] = true;
  }
}

contract Codex {
  address stone;
  uint256 aeon;
  address adept;
  address materia;
  bytes4 essence;

  function prepare(address _adept, address _materia, bytes4 _essence) external {
      if (stone != address(0)) revert();
      stone = msg.sender;
      aeon = block.number;
      adept = _adept;
      materia = _materia;
      essence = _essence;
  }

  function distill() external {
      if (msg.sender != adept) revert();
      if (aeon != block.number) revert();
      (bool transformed, bytes memory substance) = materia.call(
          hex"ab12acadab12aa"
      );
      if (!transformed) revert();
      bytes4 element = abi.decode(substance, (bytes4));
      if (element != essence) revert();
      PhilosophersStone(stone).alter(msg.sender);
      selfdestruct(payable(msg.sender));
  }

  function destroy() external {
      if (msg.sender != adept) revert();
      if (aeon != block.number) revert();
      (bool transformed, bytes memory substance) = materia.call(
          hex"ab12acadab12aa"
      );
      selfdestruct(payable(msg.sender));
  }

  function deceive() external {
      if (msg.sender != adept) revert();
      if (aeon != block.number) revert();
      (bool transformed, bytes memory substance) = materia.call(
          hex"ab12acadab12aa"
      );
      if (!transformed) revert();
      bytes4 element = abi.decode(substance, (bytes4));
      if (element != essence) revert();
      selfdestruct(payable(msg.sender));
  }

  function dismay() external {
      if (msg.sender != adept) revert();
      if (aeon != block.number) revert();
      (bool transformed, bytes memory substance) = materia.call(
          hex"ab12acadab12aa"
      );
      revert();
  }
}
