// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract CurtaToken is ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _initialOwner) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init(_initialOwner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
