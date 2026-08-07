// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BOND is ERC20, Ownable {
    constructor() ERC20("Bond", "BOND") Ownable(msg.sender) { }

    function mint(address who, uint256 amount) external onlyOwner {
        _mint(who, amount);
    }
}
