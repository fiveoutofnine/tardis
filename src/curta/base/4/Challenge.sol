pragma solidity ^0.8.20;

import "./PairAssetManager.sol";
import "./UniswapV2Factory.sol";
import "./Keeper.sol";
import "./CurtaToken.sol";

contract Deployer {
    function create(address owner, address factory) external returns (PairAssetManager) {
        return new PairAssetManager(owner, factory);
    }
}

contract Challenge {
    UniswapV2Factory public factory;
    PairAssetManager public assetManager;
    Keeper public keeper;

    CurtaToken public curtaUSD;
    CurtaToken public curtaStUSD;

    uint256 public seed;
    bool public initialized;

    function init(uint256 _seed) external {
        require(!initialized);
        initialized = true;
        seed = _seed;

        factory = new UniswapV2Factory(address(0));
        assetManager = Deployer(address(0x1D1f5f03feDD0358e7eB8A980870ef6695834bB9)).create(address(this), address(factory));
        keeper = new Keeper(address(assetManager));
        assetManager.setKeeper(address(keeper));
        curtaUSD = new CurtaToken("curtaUSD", "USD");
        curtaStUSD = new CurtaToken("curtaStUSD", "stUSD");

        curtaUSD.mint(address(this), 1 ether);
        curtaStUSD.mint(address(this), 1 ether);

        curtaUSD.approve(address(assetManager), 1 ether);
        curtaStUSD.approve(address(assetManager), 1 ether);

        factory.createPair(address(curtaUSD), address(curtaStUSD));
        assetManager.setStrategyPair(address(curtaUSD), address(curtaStUSD));
        assetManager.deposit(address(curtaUSD), address(curtaStUSD), 1 ether, 1 ether, 0);

        curtaUSD.mint(address(keeper), 10000 ether + 1);
        curtaStUSD.mint(address(keeper), 10000 ether + 1);

        keeper.rebalancing(address(curtaUSD), address(curtaStUSD), 1, 0, type(uint256).max, type(uint256).max);
    }

    function isSolved() external view returns (bool) {
        require(
            curtaUSD.balanceOf(address(uint160(seed))) == 10000 ether
                && curtaStUSD.balanceOf(address(uint160(seed))) == 10000 ether
        );
        return true;
    }
}
