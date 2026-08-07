// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract CurtaRebasingToken is ERC20Upgradeable, OwnableUpgradeable {
    IERC20 public underlyingToken;
    uint256 public unavaliableLiquidity;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _underlyingToken, address _initialOwner)
        external
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init(_initialOwner);

        underlyingToken = IERC20(_underlyingToken);
    }

    function deposit(uint256 amount) external {
        _mint(msg.sender, amount * 1e18 / getExchangeRate());
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
    }

    function withdraw(uint256 amount) external {
        require(super.balanceOf(msg.sender) >= amount);
        require(IERC20(underlyingToken).transfer(msg.sender, amount * getExchangeRate() / 1e18));
        _burn(msg.sender, amount);
    }

    function addYield(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
    }

    function invest(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transfer(msg.sender, amount));
        unavaliableLiquidity += amount;
    }

    function payback(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
        unavaliableLiquidity -= amount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * getExchangeRate() / 1e18;
    }

    function shareBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function getExchangeRate() public view returns (uint256) {
        if (super.totalSupply() == 0) {
            return 1e18;
        }
        return (underlyingToken.balanceOf(address(this)) + unavaliableLiquidity) * 1e18 / super.totalSupply();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() * getExchangeRate() / 1e18;
    }
}
