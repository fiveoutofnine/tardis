// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./CurtaToken.sol";
import "./CurtaRebasingToken.sol";
import "./CurtaLending.sol";

contract Challenge is OwnableUpgradeable {
    CurtaToken public curtaUSD;
    CurtaToken public curtaWETH;
    CurtaRebasingToken public curtaRebasingETH;
    CurtaLending public curtaLending;

    uint256 public seed;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        address _curtaUSD,
        address _curtaWETH,
        address _curtaRebasingETH,
        address _curtaLending,
        uint256 _seed
    ) external initializer {
        __Ownable_init(_initialOwner);

        curtaUSD = CurtaToken(_curtaUSD);
        curtaWETH = CurtaToken(_curtaWETH);
        curtaRebasingETH = CurtaRebasingToken(_curtaRebasingETH);
        curtaLending = CurtaLending(_curtaLending);

        seed = _seed;
    }

    function isSolved() external view returns (bool) {
        require(
            curtaUSD.balanceOf(address(uint160(seed))) == 20000 ether
                && curtaWETH.balanceOf(address(uint160(seed))) == 30000 ether
        );
        return true;
    }
}
