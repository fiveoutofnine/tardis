pragma solidity 0.8.20;

import {IPuzzle} from "lib/IPuzzle.sol";

import {IERC1822Proxiable} from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract SafeCurta is IPuzzle {
    mapping(uint => SafeChallenge) public factories;

    function name() external pure returns (string memory){
        return "ZSafe";
    }

    function generate(address _seed) public returns (uint256){
        return uint256(keccak256(abi.encode("Can you unlock the safe?", _seed)));
    }

    function verify(uint256 _start, uint256) external returns (bool) {
        return factories[_start].isUnlocked();
    }

    function deploy(uint256 _start, address owner) external returns (address) {
        bytes32 rng_seed = keccak256(abi.encodePacked(_start));
        factories[_start] = new SafeChallenge(owner, rng_seed);
        return address(factories[_start]);
    }

}

contract SafeChallenge {
    bytes32 public seed;
    SafeProxy public proxy;
    bool public isUnlocked;

    constructor(address owner, bytes32 _seed){
        //init both
        SafeProxy impl1 = new SafeSecret();
        SafeProxy impl2 = new SafeSecretAdmin();

        bytes32[] memory whitelist = new bytes32[](2);
        whitelist[0] = address(impl1).codehash;
        whitelist[1] = address(impl2).codehash;

        bytes memory init_data = abi.encodeCall(impl1.initialize, (owner, whitelist));

        address proxy_impl = address(new ERC1967Proxy(address(impl1), init_data));

        proxy = SafeProxy(proxy_impl);
        seed = _seed;
        isUnlocked = false;
    }


    function unlock(bytes32[3] calldata r, bytes32[3] calldata s) external {
        for(uint i = 0; i < 2; ++i){
            require(uint(r[i]) < uint(r[i+1]));
        }

        for(uint i = 0; i < 3; ++i){
            check(r[i], s[i]);
        }

        isUnlocked = true;
    }

    function check(bytes32 _r, bytes32 _s) internal {
        uint8 v = 27;
        address owner = proxy.owner();

        //--------

        bytes32 message1_hash = keccak256(abi.encodePacked(seed, address(0xdead)));
        bytes32 r1 = transform_r1(_r);
        bytes32 s1 = transform_s1(_s);

        address signer = ecrecover(message1_hash, v, r1, s1);
        require(signer != address(0), "no sig match :<");
        require(signer == owner, "no owner match :<");

        //---------

        bytes32 message2_hash = keccak256(abi.encodePacked(seed, address(0xbeef)));
        bytes32 r2 = transform_r2(_r);
        bytes32 s2 = transform_s2(_s);

        address signer2 = ecrecover(message2_hash, v, r2, s2);
        require(signer2 != address(0), "no sig match :<");
        require(signer2 == owner, "no owner match :<");

        //--------

    }

    function transform_r1(bytes32 r) internal pure returns (bytes32) {
        return r;
    }

    function transform_s1(bytes32 s) internal view returns (bytes32) {
        return bytes32(uint256(s) ^ proxy.p2());
    }

    function transform_r2(bytes32 r) internal view returns (bytes32) {
        unchecked{
            return bytes32(uint256(r) + proxy.p1());
        }
    }

    function transform_s2(bytes32 s) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(uint256(s) ^ proxy.p2(), seed));
    }
}

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
