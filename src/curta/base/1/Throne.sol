// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";
import {DAO} from "./DAO.sol";

contract Throne is IPuzzle {
    DAO public dao;

    mapping(address => bool) public usurpers;
    mapping(uint256 => bool) public thrones;

    constructor() {
        address[] memory allowedTargets = new address[](1);
        allowedTargets[0] = address(this);

        bytes4[] memory allowedMethods = new bytes4[](1);
        allowedMethods[0] = Throne.forgeThrone.selector;
        // no usurpers allowed

        dao = new DAO(allowedTargets, allowedMethods);
    }

    function name() external pure returns (string memory) {
        return "Usurper's Throne";
    }

    modifier onlyDAO() {
        require(msg.sender == address(dao), "only the DAO can add winners");
        _;
    }

    function addUsurper(address who) external onlyDAO {
        usurpers[who] = true;
    }

    function forgeThrone(uint256 throne) external onlyDAO {
        thrones[throne] = true;
    }

    function generate(address seed) external view returns (uint256) {
        return uint256(uint160(seed));
    }

    function verify(
        uint256 seed,
        uint256 solution
    ) external view returns (bool) {
        address solver = address(uint160(seed));
        require(solution == uint256(keccak256(abi.encode(solver))));
        return usurpers[solver] && thrones[solution];
    }
}
