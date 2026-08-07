pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract CurtaToken is ERC20 {
    address public owner;

    constructor(string memory name_, string memory symbol_, address owner_) ERC20(name_, symbol_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
