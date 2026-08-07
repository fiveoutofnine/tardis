// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

struct service {
    function(uint32, uint256) internal helper;
}

enum Mode {
    Normal,
    Development,
    Maintenance
}

contract Challenge is IPuzzle {
    mapping(address => service) private serv;
    mapping(address => Mode) public mode;
    mapping(address => uint256) public victim;
    mapping(address => uint16) value;

    // For the solver check.
    mapping(address => uint256) public solved;


    function name() external pure returns (string memory){
        return "The Fundamental";
    }

    function generate(address _seed) public returns (uint256){
        return uint256(keccak256(abi.encode("Are you a fundamentals enjoyooor?", _seed))) >> 3;
    }

    function verify(uint256 _start, uint256 _solution) external returns (bool) {
        address addr = address(uint160(_solution));

        require(generate(addr) == _start, "Expected correct message");
        return solved[addr] == _start;
    }

    function setSlot(uint256 ptr, uint16 val) public {
        victim[msg.sender] = ptr;
        value[msg.sender] = val;
    }

    function applySlot() external {
        uint256 ptr = victim[msg.sender];
        uint32 val = value[msg.sender];

        assembly {
            sstore(ptr, val)
        }
    }

    function solve(uint32 key, uint256 key2) external {
        // Wow you are zero address!
        if(msg.sender == address(0)) {
            uint256 start = generate(msg.sender);
            solved[msg.sender] = start;
            return;
        }

        require(mode[msg.sender] == Mode.Maintenance, "Cannot call with current mode");
        serv[msg.sender].helper(key, key2);

        revert("Nice Try!");
    }
}
