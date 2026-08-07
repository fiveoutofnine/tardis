pragma solidity ^0.8.20;
import { IPuzzle } from "curta/interfaces/IPuzzle.sol";
import {SafeChallenge} from "./SafeChallenge.sol";

contract SafeCurta is IPuzzle {

    mapping(uint => SafeChallenge) public factories;

    function name() external pure returns (string memory){
        return "ZSafe";
    }

    function generate(address _seed) public returns (uint256){
        return uint256(keccak256(abi.encode("Can you unlock the safe?", _seed)));
    }

    function verify(uint256 _start, uint256) external returns (bool) {
        return factories[_start].isUnlocked();
    }

    function deploy(uint256 _start, address owner) external returns (address) {
        bytes32 rng_seed = keccak256(abi.encodePacked(_start));
        factories[_start] = new SafeChallenge(owner, rng_seed);
        return address(factories[_start]);
    }

}
