pragma solidity ^0.8.20;

import "./UniswapV2Pair.sol";

contract PairAssetManager {
    struct userInfo {
        address tokenA;
        address tokenB;
        uint256 amount;
    }

    bytes32 public constant UNISWAPV2_PAIR_CODE_HASH = keccak256(type(UniswapV2Pair).runtimeCode);

    IUniswapV2Factory public factory;

    address public owner;
    address public keeper;

    mapping(address => mapping(address => address)) public strategyPair;
    mapping(address => userInfo) public users;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper);
        _;
    }

    modifier onlyUniswapV2Pair() {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(caller())
        }
        require(codeHash == UNISWAPV2_PAIR_CODE_HASH);
        _;
    }

    constructor(address owner_, address _factory) {
        owner = owner_;
        factory = IUniswapV2Factory(_factory);
    }

    function deposit(address tokenA, address tokenB, uint256 amount0, uint256 amount1, uint256 minLPAmount) external {
        require(strategyPair[tokenA][tokenB] != address(0));
        require(amount0 > 0 && amount1 > 0);

        userInfo memory user = users[msg.sender];

        if (user.tokenA == address(0) && user.tokenB == address(0)) {
            _createUser(msg.sender, tokenA, tokenB);
        }

        IUniswapV2Pair pair = IUniswapV2Pair(strategyPair[tokenA][tokenB]);
        IERC20(tokenA).transferFrom(msg.sender, address(pair), amount0);
        IERC20(tokenB).transferFrom(msg.sender, address(pair), amount1);

        uint256 lpAmount = pair.balanceOf(address(this));
        pair.mint(address(this));
        lpAmount = pair.balanceOf(address(this)) - lpAmount;

        require(lpAmount >= minLPAmount);

        users[msg.sender].amount += lpAmount;
    }

    function withdraw(uint256 amount, uint256 minAmount0, uint256 minAmount1) external {
        userInfo memory user = users[msg.sender];

        require(user.tokenA != address(0) && user.tokenB != address(0));
        require(user.amount >= amount);

        IUniswapV2Pair pair = IUniswapV2Pair(strategyPair[user.tokenA][user.tokenB]);

        uint256 tokenABalance = IERC20(user.tokenA).balanceOf(address(this));
        uint256 tokenBBalance = IERC20(user.tokenB).balanceOf(address(this));

        pair.transfer(address(pair), amount);
        pair.burn(address(this));

        tokenABalance = IERC20(user.tokenA).balanceOf(address(this)) - tokenABalance;
        tokenBBalance = IERC20(user.tokenB).balanceOf(address(this)) - tokenBBalance;

        require(tokenABalance >= minAmount0 && tokenBBalance >= minAmount1);

        users[msg.sender].amount -= amount;

        uint256 tokenAFeeAmount = tokenABalance / 10000 + 1;
        uint256 tokenBFeeAmount = tokenABalance / 10000 + 1;

        IERC20(user.tokenA).transfer(msg.sender, tokenABalance - tokenAFeeAmount);
        IERC20(user.tokenB).transfer(msg.sender, tokenBBalance - tokenBFeeAmount);

        IERC20(user.tokenA).transfer(keeper, tokenAFeeAmount);
        IERC20(user.tokenB).transfer(keeper, tokenBFeeAmount);
    }

    function _createUser(address user, address tokenA, address tokenB) private {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        users[user].tokenA = token0;
        users[user].tokenB = token1;
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data)
        external
        onlyUniswapV2Pair
    {
        IUniswapV2Pair pair = IUniswapV2Pair(msg.sender);

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amount0In = _getAmountIn(amount0, reserve1, reserve0);
        uint256 amount1In = _getAmountIn(amount1, reserve0, reserve1);

        (address tokenA, address tokenB, uint256 maxAmount0In, uint256 maxAmount1In) =
            abi.decode(data, (address, address, uint256, uint256));

        if (amount0In > maxAmount0In) {
            amount0In = maxAmount0In;
        }
        if (amount1In > maxAmount1In) {
            amount1In = maxAmount1In;
        }

        require(IERC20(tokenA).transferFrom(keeper, msg.sender, amount0In));
        require(IERC20(tokenB).transferFrom(keeper, msg.sender, amount1In));
    }

    function rebalancing(
        address tokenA,
        address tokenB,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 maxAmount0In,
        uint256 maxAmount1In
    ) external onlyKeeper {
        require(strategyPair[tokenA][tokenB] != address(0));
        IUniswapV2Pair pair = IUniswapV2Pair(strategyPair[tokenA][tokenB]);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        uint256 tokenABalance = IERC20(token0).balanceOf(address(this));
        uint256 tokenBBalance = IERC20(token1).balanceOf(address(this));

        pair.swap(
            amount0Out, amount1Out, address(this), abi.encode(pair.token0(), pair.token1(), maxAmount0In, maxAmount1In)
        );

        tokenABalance = IERC20(token0).balanceOf(address(this)) - tokenABalance;
        tokenBBalance = IERC20(token1).balanceOf(address(this)) - tokenBBalance;

        require(IERC20(token0).transfer(msg.sender, tokenABalance));
        require(IERC20(token1).transfer(msg.sender, tokenBBalance));
    }

    function setStrategyPair(address _tokenA, address _tokenB) external {
        require(factory.getPair(_tokenA, _tokenB) != address(0));

        strategyPair[_tokenA][_tokenB] = factory.getPair(_tokenA, _tokenB);
        strategyPair[_tokenB][_tokenA] = factory.getPair(_tokenA, _tokenB);
    }

    function setKeeper(address newOperator) external onlyOwner {
        keeper = newOperator;
    }
}
