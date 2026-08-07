pragma solidity ^0.8.20;

import "./PriceOracle.sol";

contract CurtaOracle is PriceOracle {
    address public owner;
    mapping(address => uint256) priceOf;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setPrice(address cToken, uint256 price) external onlyOwner {
        priceOf[cToken] = price;
    }

    function getUnderlyingPrice(CToken cToken) external view virtual override returns (uint256) {
        return priceOf[address(cToken)];
    }
}
