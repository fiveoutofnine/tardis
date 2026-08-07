// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IPuzzle } from "curta/src/interfaces/IPuzzle.sol";
import { LibClone } from "solady/src/utils/LibClone.sol";

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

  constructor() {
    bytes memory elixir = (
      hex"608060405234801561001057600080fd5b50600436106100575760003560e01c806383"
      hex"197ef01461005c578063841271ed146100665780638bbbb2e21461006e578063a69dc2"
      hex"7414610081578063cd57c8ea14610089575b600080fd5b610064610091565b005b6100"
      hex"64610128565b61006461007c36600461046f565b610264565b6100646102d3565b6100"
      hex"6461035c565b6002546001600160a01b031633146100a857600080fd5b436001541461"
      hex"00b657600080fd5b6003546040516655895656d5895560c91b81526000918291600160"
      hex"0160a01b03909116906007016000604051808303816000865af19150503d8060008114"
      hex"61011a576040519150601f19603f3d011682016040523d82523d6000602084013e6101"
      hex"1f565b606091505b50909250905033ff5b6002546001600160a01b0316331461013f57"
      hex"600080fd5b436001541461014d57600080fd5b6003546040516655895656d5895560c9"
      hex"1b815260009182916001600160a01b0390911690600701600060405180830381600086"
      hex"5af19150503d80600081146101b1576040519150601f19603f3d011682016040523d82"
      hex"523d6000602084013e6101b6565b606091505b5091509150816101c557600080fd5b60"
      hex"00818060200190518101906101db91906104b6565b6003549091506001600160e01b03"
      hex"19808316600160a01b90920460e01b161461020357600080fd5b60005460405163b10a"
      hex"582160e01b81523360048201526001600160a01b039091169063b10a58219060240160"
      hex"0060405180830381600087803b15801561024857600080fd5b505af115801561025c57"
      hex"3d6000803e3d6000fd5b503392505050ff5b6000546001600160a01b03161561027a57"
      hex"600080fd5b600080546001600160a01b03199081163317909155436001556002805460"
      hex"01600160a01b0395861692169190911790556003805460e09290921c600160a01b0260"
      hex"01600160c01b03199092169290931691909117179055565b6002546001600160a01b03"
      hex"1633146102ea57600080fd5b43600154146102f857600080fd5b600354604051665589"
      hex"5656d5895560c91b815260009182916001600160a01b03909116906007016000604051"
      hex"808303816000865af19150503d8060008114610057576040519150601f19603f3d0116"
      hex"82016040523d82523d6000602084013e600080fd5b6002546001600160a01b03163314"
      hex"61037357600080fd5b436001541461038157600080fd5b6003546040516655895656d5"
      hex"895560c91b815260009182916001600160a01b03909116906007016000604051808303"
      hex"816000865af19150503d80600081146103e5576040519150601f19603f3d0116820160"
      hex"40523d82523d6000602084013e6103ea565b606091505b5091509150816103f9576000"
      hex"80fd5b60008180602001905181019061040f91906104b6565b60035490915060016001"
      hex"60e01b0319808316600160a01b90920460e01b161461043757600080fd5b33ff5b8035"
      hex"6001600160a01b038116811461045157600080fd5b919050565b6001600160e01b0319"
      hex"8116811461046c57600080fd5b50565b60008060006060848603121561048457600080"
      hex"fd5b61048d8461043a565b925061049b6020850161043a565b915060408401356104ab"
      hex"81610456565b809150509250925092565b6000602082840312156104c857600080fd5b"
      hex"81516104d381610456565b939250505056fea164736f6c6343000815000a"
    );
    assembly {
      return(add(elixir, 0x20), mload(elixir))
    }
  }
}
