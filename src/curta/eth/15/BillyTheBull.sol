// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { IPuzzle } from "./interfaces/IPuzzle.sol";
import { IERC721 } from "./interfaces/IERC721.sol";

/**
You are Billy the Bull, the most infamous of NFT influencers.
Your trades move markets,
    your lambos fill Instagram timelines,
        your Twitter threads are the stuff of legends.

There's just one problem: you're broke.

With just one more trade, you'd certainly earn it all back.
But your mom is done lending you money, and there's nowhere left to turn.

A new mint has just opened up on The NFT Outlet. You _know_ it'll be a hit.
Your strategy is clear: You need 2 NFTs. Sell one. Keep the other for your collection.
If only there were a way to get them without paying...
*/
contract BillyTheBull is IPuzzle {
    address public owner;
    NFTOutlet public nftOutlet;
    uint public nftPrice;
    uint cachedSolution;

    event OwnsBoth(address indexed wallet, uint tokenId1, uint tokenId2);

    constructor() {
        owner = address(tx.origin);
    }

    function initialize(address _nftOutlet, uint _startingNftPrice) external {
        require(address(nftOutlet) == address(0), "already initialized");
        nftOutlet = NFTOutlet(_nftOutlet);
        nftPrice = _startingNftPrice;
    }

    function name() public pure returns (string memory) {
        return "Billy the Bull";
    }

    function generate(address _seed) public pure returns (uint256 start) {
        start = uint256(keccak256(abi.encode(_seed)));
    }

    function verify(uint _start, uint _solution) public noTampering(_solution) returns (bool) {
        // decode & cache input arguments
        uint tokenId1 = _start >> 128;
        uint tokenId2 = uint(uint128(_start));
        address wallet = address(uint160(_solution));
        IERC721 nftToBuy = nftOutlet.nftDealOfTheDay();

        // use external logic with local storage to determine the ~~magic flag~~
        bytes32 pre = keccak256(abi.encode(owner, nftOutlet, nftPrice, cachedSolution, nftToBuy.totalSupply()));
        (, bytes memory d0) = wallet.delegatecall(abi.encodeWithSignature("getMagicFlag()"));
        bytes32 post = keccak256(abi.encode(owner, nftOutlet, nftPrice, cachedSolution, nftToBuy.totalSupply()));
        require(pre == post, "bad boy");

        // ensure we have a unique magic flag
        bytes memory magicFlag = abi.decode(d0, (bytes));
        require(nftOutlet.magicFlagsUsed(keccak256(magicFlag)) == false, "no reusing flags");
        nftOutlet.setMagicFlagUsed(keccak256(magicFlag));

        // alright houdini, pay without paying
        uint balanceBefore = nftOutlet.paymentToken().balanceOf(wallet);
        (bool s1, bytes memory d1) = address(nftOutlet).call(
            abi.encodeWithSignature("pay(address,uint256)", wallet, _incrementNFTPrice(1e18))
        );
        require(!_returnedFalse(s1, d1), "transfer must succeed");
        require(balanceBefore == nftOutlet.paymentToken().balanceOf(wallet), "sneaky sneaky");

        // mint an nft to your wallet
        (bool s2, bytes memory d2) = address(nftOutlet).call(
            abi.encodeWithSignature("mint(address,uint256)", wallet, tokenId1)
        );
        require(!_returnedFalse(s2, d2), "mint must succeed");

        // did you end up with both nfts?
        require(nftToBuy.ownerOf(tokenId1) == wallet, "must own token id 1");
        require(nftToBuy.ownerOf(tokenId2) == wallet, "must own token id 2");
        emit OwnsBoth(wallet, tokenId1, tokenId2);

        // you win ... if you got the magic flag right
        return uint(keccak256(magicFlag)) == _solution;
    }

    function _returnedFalse(bool success, bytes memory data) internal pure returns (bool) {
        return success && !abi.decode(data, (bool));
    }

    function _incrementNFTPrice(uint _incrementBy) public returns (uint oldPrice) {
        require(_incrementBy < 10e18, "lets keep this affordable");
        oldPrice = nftPrice;
        nftPrice = nftPrice + _incrementBy;
    }

    modifier noTampering(uint _solution) {
        if (cachedSolution == 0) {
            cachedSolution = _solution;
            _;
            cachedSolution = 0;
        } else {
            require(cachedSolution == _solution, "max one solution");
            _;
        }
    }
}

contract NFTOutlet {
    address immutable puzzle;

    ERC20 public paymentToken;
    IERC721 public nftDealOfTheDay;
    address treasury;

    mapping(address => bool) public validAssets;
    mapping(address => bool) public mintsClaimed;
    mapping(bytes32 => bool) public magicFlagsUsed;

    constructor(
        address _puzzle,
        address[] memory _paymentTokens,
        address[] memory _nfts
    ) {
        puzzle = _puzzle;
        paymentToken = ERC20(_paymentTokens[0]);
        nftDealOfTheDay = IERC721(_nfts[0]);

        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            validAssets[_paymentTokens[i]] = true;
        }

        for (uint256 i = 0; i < _nfts.length; i++) {
            validAssets[_nfts[i]] = true;
        }
    }

    /////////////////////////
    /////// MODIFIERS ///////
    /////////////////////////

    modifier onlyPuzzle() {
        require(msg.sender == puzzle, "only puzzle");
        _;
    }

    modifier onlyPuzzleOwner() {
        require(msg.sender == BillyTheBull(puzzle).owner(), "only puzzle owner");
        _;
    }

    /////////////////////////
    //// PAYMENT ACTIONS ////
    /////////////////////////

    function pay(address _from, uint256 _amount) public onlyPuzzle returns (bool) {
        require(_from != address(0), "no zero address");
        try paymentToken.transferFrom(_from, address(this), _amount) returns (bool) {
            require(
                keccak256(abi.encode(_amount)) !=
                0x420badbabe420badbabe420badbabe420badbabe420badbabe420badbabe6969,
                "too immature"
            );
            return true;
        } catch {
            require(uint(uint32(_amount)) <= 4294967295, "invalid amount");
            return false;
        }
    }

    /////////////////////////
    //// MINTING ACTIONS ////
    /////////////////////////

    function mint(address _to, uint256 _tokenId) public onlyPuzzle returns (bool) {
        require(!mintsClaimed[_to], "already claimed");
        try nftDealOfTheDay.safeMint(_to, _tokenId) {
            mintsClaimed[_to] = true;
            return true;
        } catch {
            return false;
        }
    }

    /////////////////////////
    ///// ADMIN ACTIONS /////
    /////////////////////////

    function setMagicFlagUsed(bytes32 _magicFlag) onlyPuzzle public {
        magicFlagsUsed[_magicFlag] = true;
    }

    function changePaymentToken(address _newStablecoin) public onlyPuzzleOwner {
        require(validAssets[_newStablecoin], "no sneaky assets");
        paymentToken = ERC20(_newStablecoin);
    }

    function rescueERC20(address _token) public {
        ERC20(_token).transfer(treasury, ERC20(_token).balanceOf(address(this)));
    }
}
