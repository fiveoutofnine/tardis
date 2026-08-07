pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./PairAssetManager.sol";

contract Keeper {
    address public owner;
    PairAssetManager public assetManager;

    constructor(address _assetManager) {
        assetManager = PairAssetManager(_assetManager);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function rebalancing(
        address tokenA,
        address tokenB,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 maxAmount0In,
        uint256 maxAmount1In
    ) external onlyOwner {
        IERC20(tokenA).approve(address(assetManager), type(uint256).max);
        IERC20(tokenB).approve(address(assetManager), type(uint256).max);
        assetManager.rebalancing(tokenA, tokenB, amount0Out, amount1Out, maxAmount0In, maxAmount1In);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
