// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./CurtaToken.sol";
import "./CurtaRebasingToken.sol";
import "./Oracle.sol";
import "./CurtaLending.sol";
import "./Challenge.sol";

contract ChallFactory is Ownable {
    address immutable tokenImplementation;
    address immutable rebasingTokenImplementation;
    address immutable oracleImplementation;
    address immutable curtaLendingImplementation;
    address immutable challengeImplementation;

    constructor(address _curta) Ownable(_curta) {
        tokenImplementation = address(new CurtaToken());
        rebasingTokenImplementation = address(new CurtaRebasingToken());
        oracleImplementation = address(new Oracle());
        curtaLendingImplementation = address(new CurtaLending());
        challengeImplementation = address(new Challenge());
    }

    function createChallenge(uint256 seed, address player) external onlyOwner returns (address) {
        address usdClone = Clones.clone(tokenImplementation);
        address wethClone = Clones.clone(tokenImplementation);
        address rebasingWETHClone = Clones.clone(rebasingTokenImplementation);
        address oracleClone = Clones.clone(oracleImplementation);
        address curtaLendingClone = Clones.clone(curtaLendingImplementation);
        address challClone = Clones.clone(challengeImplementation);

        CurtaToken(usdClone).initialize("CurtaUSD", "USD", address(this));
        CurtaToken(wethClone).initialize("CurtaWETH", "WETH", address(this));
        CurtaRebasingToken(rebasingWETHClone).initialize("CurtaRebasingWETH", "RebasingWETH", wethClone, address(this));
        Oracle(oracleClone).initialize(address(this));
        CurtaLending(curtaLendingClone).initialize(address(this), oracleClone);
        Challenge(challClone).initialize(address(this), usdClone, wethClone, rebasingWETHClone, curtaLendingClone, seed);

        Oracle(oracleClone).setPrice(usdClone, 1e18);
        Oracle(oracleClone).setPrice(wethClone, 3000e18);
        Oracle(oracleClone).setPrice(rebasingWETHClone, 3100e18);

        CurtaLending(curtaLendingClone).setAsset(usdClone, true, 500, 0.8 ether, 0.9 ether, 0.05 ether);
        CurtaLending(curtaLendingClone).setAsset(wethClone, true, 300, 0.7 ether, 0.8 ether, 0.05 ether);
        CurtaLending(curtaLendingClone).setAsset(rebasingWETHClone, true, 300, 0.7 ether, 0.8 ether, 0.05 ether);

        CurtaToken(usdClone).mint(address(this), 10000 ether);
        CurtaToken(wethClone).mint(address(this), 20000 ether);
        CurtaToken(wethClone).approve(rebasingWETHClone, 10000 ether);
        CurtaRebasingToken(rebasingWETHClone).deposit(10000 ether);

        CurtaToken(usdClone).mint(player, 10000 ether);
        CurtaToken(wethClone).mint(player, 10000 ether);

        CurtaToken(usdClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(usdClone, 10000 ether);
        CurtaToken(wethClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(wethClone, 10000 ether);
        CurtaRebasingToken(rebasingWETHClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(rebasingWETHClone, 10000 ether);

        return challClone;
    }
}
