// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@solmate/tokens/ERC721.sol";

contract FreeWilly is ERC721 {
    string BASE_URL;

    /////////////////////////
    ///////// SETUP /////////
    /////////////////////////

    constructor() ERC721("Free Willy", "WILLY") {
        BASE_URL = "ipfs://QmfAzi4uxRd3WPym5yVyQRQc4CjvDrubG6tzq3yhNVEGNQ/";
    }

    /////////////////////////
    //////// EXTERNAL ///////
    /////////////////////////

    // Public mint. No cost. Welcome to the Free Willy family.
    function mint(uint tokenId) public {
        _mint(msg.sender, tokenId);
    }

    // It's not much, but it's free, so no complaining.
    function tokenURI(uint256) public view override returns (string memory) {
        return BASE_URL;
    }
}
