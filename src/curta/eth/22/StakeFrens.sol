// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";
import {IDepositEvents, IDepositContract} from "./interfaces/IDepositContract.sol";
import {IReliquary} from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import {IProver} from "relic-sdk/packages/contracts/interfaces/IProver.sol";
import {Fact, FactSignature} from "relic-sdk/packages/contracts/lib/Facts.sol";
import {FactSigs} from "relic-sdk/packages/contracts/lib/FactSigs.sol";
import {CoreTypes} from "relic-sdk/packages/contracts/lib/CoreTypes.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakeFrens is IPuzzle {
    IReliquary public constant RELIQUARY =
        IReliquary(0x5E4DE6Bb8c6824f29c44Bd3473d44da120387d08);
    FrenCoin public immutable frenCoin;

    mapping (address => FrenPool) public pools;

    constructor() {
        frenCoin = new FrenCoin(this);
    }

    function name() external pure returns (string memory) {
        return "Stake Frens";
    }

    function generate(address seed) external view returns (uint256) {
        return uint256(uint160(seed));
    }

    function verify(uint256 seed, uint256 solution) external view returns (bool) {
        address challenger = address(uint160(seed));
        require(
            solution == uint256(uint128(uint256(keccak256(abi.encode(seed))))),
            "invalid solution"
        );

        return frenCoin.balanceOf(challenger) == solution;
    }

    function createPool() external payable returns (FrenPool pool) {
        pool = new FrenPool(msg.sender, RELIQUARY);
        pools[msg.sender] = pool;
    }

    function joinPool(address creator, address prover, FrenPool.DepositProof calldata proof) external payable {
        FrenPool pool = pools[creator];
        require(address(pool) != address(0), "pool doesn't exist");
        pool.join{value: msg.value}(msg.sender, prover, proof);
    }
}

contract FrenPool is Ownable, IDepositEvents {
    struct DepositProof {
        uint256 blockNum;
        uint256 txIdx;
        uint256 logIdx;
        bytes32 expectedRoot;
        bytes proof;
    }

    bytes1 constant ETH1_ADDRESS_WITHDRAWAL_PREFIX = hex"01";
    IDepositContract constant ETH_DEPOSIT_CONTRACT =
        IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    uint256 constant FAIR_DEPOSIT_AMOUNT = 16 ether;

    IReliquary public immutable reliquary;
    bytes32 immutable DEPOSIT_AMOUNT_KECCAK;

    address fren;
    mapping(address => uint256) collected;

    function to_little_endian_64(
        uint64 value
    ) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

    constructor(address owner, IReliquary _reliquary) Ownable(owner) {
        reliquary = _reliquary;
        DEPOSIT_AMOUNT_KECCAK = keccak256(
            to_little_endian_64(uint64(FAIR_DEPOSIT_AMOUNT / 1 gwei))
        );
    }

    function eth1WithdrawalCredentials()
        public
        view
        returns (bytes memory creds)
    {
        return
            abi.encodePacked(
                ETH1_ADDRESS_WITHDRAWAL_PREFIX,
                uint248(uint160(address(this)))
            );
    }

    function verifyProver(address prover) internal view {
        // check that it's a valid Relic prover
        IReliquary.ProverInfo memory info = reliquary.provers(prover);
        require(info.version > 0 && !info.revoked, "Invalid prover provided");
    }

    function verifyDeposit(
        address prover,
        DepositProof calldata proof
    ) internal returns (bytes memory pubkey) {
        Fact memory fact = IProver(prover).prove(proof.proof, false);
        FactSignature expected = FactSigs.logFactSig(
            proof.blockNum,
            proof.txIdx,
            proof.logIdx
        );
        require(
            FactSignature.unwrap(fact.sig) == FactSignature.unwrap(expected),
            "fact signature is incorrect"
        );
        CoreTypes.LogData memory logData = abi.decode(
            fact.data,
            (CoreTypes.LogData)
        );
        require(
            logData.Topics[0] == DepositEvent.selector,
            "incorrect log event proven"
        );
        DepositEventData memory eventData = abi.decode(
            logData.Data,
            (DepositEventData)
        );
        require(
            keccak256(eventData.amount) == DEPOSIT_AMOUNT_KECCAK,
            "incorrect deposit amount"
        );
        require(
            keccak256(eventData.withdrawal_credentials) ==
                keccak256(eth1WithdrawalCredentials()),
            "incorrect withdrawal credentials"
        );
        require(
            IDepositContract(fact.account).get_deposit_root() ==
                proof.expectedRoot,
            "unexpected deposit root, potential frontrun"
        );
        return eventData.pubkey;
    }

    function computeUnsignedDepositRoot(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        uint256 deposit_amount
    ) internal pure returns (bytes32 result) {
        assert(deposit_amount % 1 gwei == 0);
        bytes memory amount = to_little_endian_64(uint64(deposit_amount / 1 gwei));
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 zeroNode = sha256(abi.encodePacked(bytes32(0), bytes32(0)));
        bytes32 signature_root = sha256(abi.encodePacked(zeroNode, zeroNode));
        result = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawal_credentials)),
            sha256(abi.encodePacked(amount, bytes24(0), signature_root))
        ));
    }

    // will you be my fren?
    function join(
        address newFren,
        address prover,
        DepositProof calldata proof
    ) external payable {
        require(fren == address(0), "already have a fren");
        require(msg.value >= FAIR_DEPOSIT_AMOUNT, "frens should pay their fair share");
        fren = newFren;

        verifyProver(prover);
        bytes memory pubkey = verifyDeposit(prover, proof);
        bytes memory credentials = eth1WithdrawalCredentials();
        bytes32 deposit_data_root = computeUnsignedDepositRoot(pubkey, credentials, msg.value);

        ETH_DEPOSIT_CONTRACT.deposit{value: msg.value}(
            pubkey,
            eth1WithdrawalCredentials(),
            new bytes(96),
            deposit_data_root
        );
    }

    function collect() external {
        require(
            msg.sender == owner() || msg.sender == fren,
            "only the owner or their fren can call"
        );
        address other = msg.sender == owner() ? fren : owner();
        uint256 diff = collected[msg.sender] - collected[other];
        uint256 amount = (address(this).balance - diff) / 2;
        collected[msg.sender] += amount;
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }
}

contract FrenCoin is ERC20 {
    StakeFrens public immutable stakeFrens;

    bytes32 constant TOO_FRENLY =
        keccak256("DepositContract: deposit value too high");

    uint256 constant HUGE = 1<<128;

    constructor(StakeFrens _stakeFrens) ERC20("FrenCoin", "FREN") {
        stakeFrens = _stakeFrens;
    }

    function showFrenship(
        address creator,
        address prover,
        FrenPool.DepositProof calldata proof
    ) external payable {
        try stakeFrens.joinPool{value: msg.value}(creator, prover, proof) {
            _mint(msg.sender, 1);
        } catch Error(string memory reason) {
            if (keccak256(abi.encodePacked(reason)) == TOO_FRENLY) {
                // too frenly
                _mint(msg.sender, HUGE);
            }

            // refund sender
            (bool success, ) = msg.sender.call{value: msg.value}("");
            assert(success);
        }
    }
}
