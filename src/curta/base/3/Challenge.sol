pragma solidity ^0.8.20;

import "./Comptroller.sol";
import "./JumpRateModel.sol";
import "./CErc20Immutable.sol";
import "./CurtaToken.sol";
import "./CurtaOracle.sol";

contract Deployer {
    function create(address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_) external returns (CErc20Immutable) {
                return new CErc20Immutable(underlying_, comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, uint8(18), payable(msg.sender));
    }

    function create2(string memory a, string memory b) external returns (CurtaToken) {
        return new CurtaToken(a, b, msg.sender);
    }
}


contract Challenge {
    uint256 public seed;

    Comptroller public comptroller;
    JumpRateModel public rateModel;

    CurtaToken public CUSD;
    CurtaToken public CStUSD;
    CurtaToken public CETH;
    CurtaToken public CWETH;

    CErc20Immutable public CCUSD;
    CErc20Immutable public CCStUSD;
    CErc20Immutable public CCETH;
    CErc20Immutable public CCWETH;

    CurtaOracle public oracle;

    bool public initialized;

    function init(uint256 _seed, address _caller) external {
        require(!initialized);
        initialized = true;
        Deployer dd = Deployer(address(0x8555a99DC962D3711101896a3f432d65E8Fbb60f));

        seed = _seed;
        CUSD = dd.create2("CUSD", "cUSD");
        CStUSD = dd.create2("CStUSD", "cStUSD");
        CETH = dd.create2("CETH", "cETH");
        CWETH = dd.create2("CWETH", "cWETH");

        CUSD.mint(address(this), 10000 ether);
        CStUSD.mint(address(this), 10000 ether);
        CETH.mint(address(this), 10000 ether);
        CWETH.mint(address(this), 10000 ether);

        rateModel = new JumpRateModel(2102400, 2102400, 2102400, type(uint256).max);
        comptroller = new Comptroller();
        oracle = new CurtaOracle();

        CCUSD =
        dd.create(address(CUSD), ComptrollerInterface(address(comptroller)), InterestRateModel(address(rateModel)), 1e18, "CCUSD", "cCUSD");
        CCStUSD =
        dd.create(address(CStUSD), ComptrollerInterface(address(comptroller)), InterestRateModel(address(rateModel)), 1e18, "CCStUSD", "cCStUSD");
        CCETH =
        dd.create(address(CETH), ComptrollerInterface(address(comptroller)), InterestRateModel(address(rateModel)), 1e18, "CCETH", "cCETH");
        CCWETH =
        dd.create(address(CWETH), ComptrollerInterface(address(comptroller)), InterestRateModel(address(rateModel)), 1e18, "CCWETH", "cCWETH");

        CUSD.approve(address(CCUSD), type(uint256).max);
        CStUSD.approve(address(CCStUSD), type(uint256).max);
        CETH.approve(address(CCETH), type(uint256).max);
        CWETH.approve(address(CCWETH), type(uint256).max);

        comptroller._supportMarket(CToken(CCUSD));
        comptroller._supportMarket(CToken(CCStUSD));
        comptroller._supportMarket(CToken(CCETH));
        comptroller._supportMarket(CToken(CCWETH));

        oracle.setPrice(address(CCUSD), 1e18);
        oracle.setPrice(address(CCStUSD), 1e18);
        oracle.setPrice(address(CCETH), 200e18);
        oracle.setPrice(address(CCWETH), 200e18);

        comptroller._setPriceOracle(PriceOracle(address(oracle)));

        comptroller._setCollateralFactor(CToken(CCUSD), 0.9 ether);
        comptroller._setCollateralFactor(CToken(CCStUSD), 0.9 ether);
        comptroller._setCollateralFactor(CToken(CCETH), 0.7 ether);
        comptroller._setCollateralFactor(CToken(CCWETH), 0.7 ether);

        comptroller._setCloseFactor(0.5 ether);
        comptroller._setLiquidationIncentive(1 ether);

        CCUSD.mint(10000 ether);
        CCStUSD.mint(10000 ether);
        CCETH.mint(10000 ether);
        // CWETH.mint(10000 ether);

        CWETH.mint(_caller, 10000 ether);
    }

    function isSolved() external view returns (bool) {
        address target = address(uint160(seed));

        uint256 initUSD = 10000 ether * oracle.getUnderlyingPrice(CToken(CCWETH)) / 1e18;

        uint256 profitUSD = (
            CUSD.balanceOf(target) * oracle.getUnderlyingPrice(CToken(CCUSD))
                + CStUSD.balanceOf(target) * oracle.getUnderlyingPrice(CToken(CCStUSD))
                + CETH.balanceOf(target) * oracle.getUnderlyingPrice(CToken(CCETH))
                + CWETH.balanceOf(target) * oracle.getUnderlyingPrice(CToken(CCWETH))
        ) / 1e18 - initUSD;

        require(profitUSD > 10000 ether * 200);

        return true;
    }
}
