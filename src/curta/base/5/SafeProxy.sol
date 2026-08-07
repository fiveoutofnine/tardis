pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IERC1822Proxiable} from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";

//Butchered implementation from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/proxy/utils/UUPSUpgradeable.sol with only the features I need
abstract contract SafeUpgradeable {
    mapping(bytes32 => bool) internal whitelist;

    address private immutable __self = address(this);

    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSafe(newImplementation, data);
    }

    function _checkProxy() internal view virtual {
        if (
            address(this) == __self ||
            ERC1967Utils.getImplementation() != __self
        ) {
            revert("No hacc");
        }
    }

    function _authorizeUpgrade(address newImplementation) internal {
        require(whitelist[newImplementation.codehash], "wtf no whitelisted no hacc pls");
    }

    function _upgradeToAndCallSafe(address newImplementation, bytes memory data) private {
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}


abstract contract SafeProxy is OwnableUpgradeable, SafeUpgradeable {
    uint256 internal p1_secret;
    uint256 internal p2_secret;

    function initialize(address owner, bytes32[] calldata whitelisted_hashes) public initializer{

        for(uint i = 0; i < whitelisted_hashes.length; ++i){
            whitelist[whitelisted_hashes[i]] = true;
        }

        p1_secret = uint256(keccak256(abi.encodePacked(keccak256(abi.encode(uint256(blockhash(block.number)))))));
        p2_secret = uint256(keccak256(abi.encodePacked(keccak256(abi.encode(p1_secret)))));

        __Ownable_init(owner);
    }

    function p1() external view virtual returns (uint256);
    function p2() external view virtual returns (uint256);
}


contract SafeSecret is SafeProxy {
    function p1() external view virtual override returns (uint256){
        return p1_secret;
    }

    function p2() external view virtual override returns (uint256){
        return p2_secret;
    }
}

contract SafeSecretAdmin is SafeProxy {
    uint256 private offsetp1;
    uint256 private offsetp2;

    function p1() external view virtual override returns (uint256){
        unchecked{
            return p1_secret+offsetp1;
        }
    }

    function p2() external view virtual override returns (uint256){
        unchecked{
            return p2_secret+offsetp2;
        }
    }

    function set_offset(uint256 _p1, uint256 _p2) external {
        offsetp1 = _p1;
        offsetp2 = _p2;
    }
}
