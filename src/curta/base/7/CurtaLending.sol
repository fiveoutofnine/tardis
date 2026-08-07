// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./Oracle.sol";

struct UserInfo {
    address borrowAsset;
    uint256 liquidityAmount;
    uint256 collateralAmount;
    uint256 liquidityIndex;
    uint256 borrowIndex;
    uint256 claimableReward;
    uint256 totalDebt;
    uint256 principal;
}

struct AssetInfo {
    bool isAsset;
    uint256 totalLiquidity;
    uint256 avaliableLiquidity;
    uint256 totalDebt;
    uint256 totalPrincipal;
    uint256 interestRate;
    uint256 avaliableClaimableReward;
    uint256 borrowLTV;
    uint256 liquidationLTV;
    uint256 liquidationBonus;
    uint256 globalIndex;
    uint256 lastUpdateBlock;
}

contract CurtaLending is OwnableUpgradeable {
    mapping(address => mapping(address => UserInfo)) public userInfo;
    mapping(address => AssetInfo) public assetInfo;

    Oracle public oracle;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner, address _oracle) external initializer {
        oracle = Oracle(_oracle);
        __Ownable_init(_initialOwner);
    }

    function setAsset(
        address _asset,
        bool _isAsset,
        uint256 _interestRate,
        uint256 _borrowLTV,
        uint256 _liquidationLTV,
        uint256 _liquidationBonus
    ) external onlyOwner {
        assetInfo[_asset].isAsset = _isAsset;
        assetInfo[_asset].interestRate = _interestRate;
        assetInfo[_asset].borrowLTV = _borrowLTV;
        assetInfo[_asset].liquidationLTV = _liquidationLTV;
        assetInfo[_asset].liquidationBonus = _liquidationBonus;
        assetInfo[_asset].lastUpdateBlock = block.number;
    }

    function depositCollateral(address asset, uint256 amount) external {
        require(assetInfo[asset].isAsset);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        uint256 liquidityAmount = _userInfo.liquidityAmount;

        if (_userInfo.liquidityAmount < amount) {
            _userInfo.collateralAmount += amount;
            _userInfo.liquidityAmount = 0;
            _assetInfo.totalLiquidity -= liquidityAmount;
            _assetInfo.avaliableLiquidity -= liquidityAmount;
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount - liquidityAmount));
        } else {
            _userInfo.collateralAmount += amount;
            _userInfo.liquidityAmount -= amount;
            _assetInfo.totalLiquidity -= amount;
            _assetInfo.avaliableLiquidity -= amount;
        }
    }

    function withdrawCollateral(address asset, uint256 amount) external {
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        uint256 collateralValue = (_userInfo.collateralAmount - amount) * oracle.getPrice(asset);
        uint256 borrowValue = _userInfo.totalDebt * oracle.getPrice(_userInfo.borrowAsset);
        require(collateralValue * _assetInfo.borrowLTV >= borrowValue * 1e18);

        if (amount == 0) {
            _userInfo.liquidityAmount += _userInfo.collateralAmount;
            _assetInfo.totalLiquidity += _userInfo.collateralAmount;
            _assetInfo.avaliableLiquidity += _userInfo.collateralAmount;
            _userInfo.collateralAmount = 0;
        } else {
            require(_userInfo.collateralAmount >= amount);
            _userInfo.liquidityAmount += amount;
            _userInfo.collateralAmount -= amount;
            _assetInfo.totalLiquidity += amount;
            _assetInfo.avaliableLiquidity += amount;
        }
    }

    function depositLiquidity(address asset, uint256 amount) external {
        require(assetInfo[asset].isAsset);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        if (_userInfo.liquidityIndex == 0) {
            _userInfo.liquidityIndex = _assetInfo.globalIndex;
        }

        uint256 beforeBalance = IERC20(asset).balanceOf(address(this));
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount));
        uint256 afterBalance = IERC20(asset).balanceOf(address(this)) - beforeBalance;

        _userInfo.liquidityAmount += afterBalance;
        _assetInfo.totalLiquidity += afterBalance;
        _assetInfo.avaliableLiquidity += afterBalance;
    }

    function withdrawLiquidity(address asset, uint256 amount) external {
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        require(_assetInfo.avaliableLiquidity >= amount);

        _userInfo.liquidityAmount -= amount;
        _assetInfo.totalLiquidity -= amount;
        _assetInfo.avaliableLiquidity -= amount;

        require(IERC20(asset).transfer(msg.sender, amount));
    }

    function borrow(address collateral, address borrowAsset, uint256 amount) external {
        require(assetInfo[borrowAsset].isAsset);
        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        require(_userInfo.borrowAsset == address(0) || _userInfo.borrowAsset == borrowAsset);

        if (_userInfo.borrowAsset == address(0)) {
            _userInfo.borrowAsset = borrowAsset;
        }

        accrueInterest(msg.sender, collateral);

        AssetInfo storage _assetInfo = assetInfo[borrowAsset];
        require(_assetInfo.avaliableLiquidity >= amount);

        if (_userInfo.borrowIndex == 0) {
            _userInfo.borrowIndex = _assetInfo.globalIndex;
        }

        uint256 collateralValue = _userInfo.collateralAmount * oracle.getPrice(collateral);
        uint256 borrowValue = amount * oracle.getPrice(borrowAsset);
        require(collateralValue * assetInfo[collateral].borrowLTV >= borrowValue * 1e18);

        _userInfo.totalDebt += amount;
        _userInfo.principal += amount;
        _assetInfo.totalDebt += amount;
        _assetInfo.totalPrincipal += amount;
        _assetInfo.avaliableLiquidity -= amount;

        require(IERC20(borrowAsset).transfer(msg.sender, amount));
    }

    function repay(address collateral, uint256 amount) external {
        accrueInterest(msg.sender, collateral);
        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        require(_userInfo.borrowAsset != address(0));

        uint256 borrowInterest = _userInfo.totalDebt - _userInfo.principal;

        if (_userInfo.totalDebt < amount) {
            amount = _userInfo.totalDebt;
        }

        _userInfo.totalDebt -= amount;
        _assetInfo.totalDebt -= amount;

        if (borrowInterest < amount) {
            _userInfo.principal -= amount - borrowInterest;
            _assetInfo.totalPrincipal -= amount - borrowInterest;
            _assetInfo.avaliableClaimableReward += borrowInterest;
            _assetInfo.avaliableLiquidity += amount - borrowInterest;
        } else {
            _assetInfo.avaliableClaimableReward += amount;
        }

        require(IERC20(_userInfo.borrowAsset).transferFrom(msg.sender, address(this), amount));
    }

    function liquidate(address user, address collateral, uint256 amount) external {
        accrueInterest(user, collateral);

        UserInfo storage _userInfo = userInfo[msg.sender][collateral];

        address asset = _userInfo.borrowAsset;

        if (_userInfo.totalDebt * 5 < amount * 10) {
            amount = _userInfo.totalDebt / 2;
        }

        uint256 collateralValue = _userInfo.collateralAmount * oracle.getPrice(collateral);
        uint256 borrowValue = _userInfo.totalDebt * oracle.getPrice(asset);
        require(collateralValue * assetInfo[collateral].liquidationLTV <= borrowValue * 1e18);

        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        uint256 refundCollateral = amount * oracle.getPrice(asset) / oracle.getPrice(collateral)
            + amount * oracle.getPrice(asset) / oracle.getPrice(collateral) * _assetInfo.liquidationBonus / 1e18;

        if (refundCollateral > _userInfo.collateralAmount) {
            refundCollateral = _userInfo.collateralAmount;
        }

        _userInfo.collateralAmount -= refundCollateral;

        uint256 borrowInterest = _userInfo.totalDebt - _userInfo.principal;

        _userInfo.totalDebt -= amount;
        _assetInfo.totalDebt -= amount;

        if (borrowInterest < amount) {
            _userInfo.principal -= amount - borrowInterest;
            _assetInfo.totalPrincipal -= amount - borrowInterest;
            _assetInfo.avaliableClaimableReward += borrowInterest;
            _assetInfo.avaliableLiquidity += amount - borrowInterest;
        } else {
            _assetInfo.avaliableClaimableReward += amount;
        }

        require(IERC20(asset).transferFrom(msg.sender, address(this), amount));
        require(IERC20(collateral).transfer(msg.sender, refundCollateral));
    }

    function resetBorrowAsset(address collateral) external {
        accrueInterest(msg.sender, collateral);

        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        require(_userInfo.borrowAsset != address(0));
        require(_userInfo.principal == 0 && _userInfo.totalDebt == 0);

        _userInfo.borrowAsset = address(0);
        _userInfo.borrowIndex = 0;
    }

    function burnBadDebt(address user, address collateral) external {
        accrueInterest(user, collateral);

        UserInfo storage _userInfo = userInfo[user][collateral];
        require(_userInfo.collateralAmount == 0 && _userInfo.totalDebt != 0);

        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        require(IERC20(_userInfo.borrowAsset).transferFrom(msg.sender, address(this), _userInfo.totalDebt));

        _assetInfo.totalDebt -= _userInfo.totalDebt;
        _assetInfo.totalPrincipal -= _userInfo.principal;
        _assetInfo.avaliableClaimableReward += _userInfo.totalDebt - _userInfo.principal;
        _assetInfo.avaliableLiquidity += _userInfo.principal;
        _userInfo.totalDebt = 0;
        _userInfo.principal = 0;
    }

    function claimReward(address asset, uint256 amount) external {
        require(assetInfo[asset].avaliableClaimableReward >= amount);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        require(_userInfo.claimableReward >= amount * 1e18);

        _userInfo.claimableReward -= amount * 1e18;
        assetInfo[asset].avaliableClaimableReward -= amount;

        require(IERC20(asset).transfer(msg.sender, amount));
    }

    function accrueInterest(address user, address asset) public {
        UserInfo storage _userInfo = userInfo[user][asset];

        if (_userInfo.liquidityIndex == 0 && _userInfo.borrowIndex == 0) {
            return;
        }

        address borrowAsset = _userInfo.borrowAsset;

        updateAsset(asset);
        updateAsset(borrowAsset);

        AssetInfo memory _assetInfo = assetInfo[asset];
        AssetInfo memory _borrowAssetInfo = assetInfo[borrowAsset];

        if (_userInfo.liquidityIndex != 0) {
            uint256 pending = _assetInfo.globalIndex - _userInfo.liquidityIndex;
            _userInfo.claimableReward += pending * 1e18 * _userInfo.liquidityAmount / _assetInfo.totalLiquidity;
            _userInfo.liquidityIndex = _assetInfo.globalIndex;
        }

        if (_userInfo.borrowIndex != 0) {
            uint256 pending = _borrowAssetInfo.globalIndex - _userInfo.borrowIndex;
            _userInfo.totalDebt += pending * _userInfo.principal / _borrowAssetInfo.totalPrincipal;
            _userInfo.borrowIndex = _borrowAssetInfo.globalIndex;

            if ((pending * _userInfo.principal) % _borrowAssetInfo.totalPrincipal != 0) {
                _userInfo.totalDebt += 1;
                _borrowAssetInfo.totalDebt += 1;
            }
        }
    }

    function updateAsset(address asset) public {
        AssetInfo storage _assetInfo = assetInfo[asset];

        if (block.number == _assetInfo.lastUpdateBlock) {
            return;
        }

        _assetInfo.globalIndex +=
            (block.number - _assetInfo.lastUpdateBlock) * _assetInfo.totalPrincipal * _assetInfo.interestRate / 10000;
        _assetInfo.totalDebt +=
            (block.number - _assetInfo.lastUpdateBlock) * _assetInfo.totalPrincipal * _assetInfo.interestRate / 10000;
        _assetInfo.lastUpdateBlock = block.number;
    }
}
