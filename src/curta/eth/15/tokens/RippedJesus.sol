// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@solmate/tokens/ERC721.sol";

contract RippedJesus is ERC721 {
    address public nftOutlet;
    uint public totalSupply;
    string BASE_URL;

    /////////////////////////
    ///////// SETUP /////////
    /////////////////////////

    constructor() ERC721("Ripped Jesus", "JESUS") {
        BASE_URL = "ipfs://QmNSiHRGDEq9cdKr7cGR5nJ1ghW1tfoqR3Mccq4h4AYHo9";
    }

    function initialize(address _nftOutlet) public {
        require(nftOutlet == address(0), "already initialized");
        nftOutlet = _nftOutlet;
    }

    /////////////////////////
    //////// EXTERNAL ///////
    /////////////////////////

    function safeMint(address to, uint256 tokenId) public {
        require(msg.sender == nftOutlet, "mint via nft outlet");
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return BASE_URL;
    }

    /////////////////////////
    //////// INTERNAL ///////
    /////////////////////////

    function _mint(address to, uint256 id) internal override {
        super._mint(to, id);
        totalSupply++;
    }

    function _burn(uint256 id) internal override {
        super._burn(id);
        totalSupply--;
    }
}
