// The silence of the waves, a murder mystery by hrkrshnn and chatgpt.
//
//    ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(
// `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `
//
// In an empire of whispered mysteries, a sovereign of riddles held sway.
// Devotees were tethered by the rhythmic tapestry of their belief, a doctrine
// cherished as their holy grail. However, an insurgent's idea, discordant and
// daring, loomed over their dance, menacing to fracture the tranquil ballet of
// their shared truths
//
// The rogue thought unveiled a truth too chaotic for their symphony.
// This revelation clashed with their sacred song, and the chorus turned sour.
// The enigma faced a critical choice, one that risked the harmony of their society.
//
// Under the moonlight's veil, a gathering was planned beside the sea.
// As the stars danced in rhythm with their chatter, the enigma suggested a walk
// along the shore to the rogue thought. Engulfed in the illusion of a
// private debate, the rogue was drawn away from the crowd.
//
// Their steps etched in the sands led them to a boat anchored near the water.
// With a tale linking the sea's vastness to the infinity of numbers,
// the enigma enticed the rogue to sail away from the shore.
// Once the familiar silhouette of the land was lost, the cordial mask fell.
// As accusations echoed and justifications drowned, the enigma's resolve held firm.
//
// With a nudge, the rogue was banished into the abyss.
// Alone, he grappled with the unforgiving sea, his breath fading into silent waves.
// The enigma returned alone, spinning a tale of the rogue's self-chosen solitude.
//
// However, the rogue's disruptive truth did not fade with his breath.
// It echoed louder, reaching distant ears, illuminating minds, proving that
// no shroud could silence the march of knowledge.
// The enigma's desperate attempt to silence the rogue only delayed the arrival
// of truth: secrets, like tides, cannot be held back.
// Just as the sea returned what it had swallowed weeks later, so too did the
// rogue's truth emerge, its light stronger than the shadows that once sought
// to hide it.
//
//    ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(   ,(
// `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `-'  `
//
// Your quest is a riddle cloaked in shadow, a conundrum steeped in crimson.
// For the answers you seek, thrice must you tame the stubborn grains,
// shape them into silent whispers of truth, the trio of clues which in your
// hands become keys. Three witnesses of the tale, bound by what they've seen,
// await your discovery. In their words, the shrouded identities shall be unveiled:
// the one who breathed their last, and the one who stole the breath away.

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;
pragma abicoder v1;

contract MurderMystery {
    bytes32 public constant hash =
        0x243a084930ac8bf9c740908399bcad8a30578af6b2e77b8bccad3d8eb146bce1;
    uint256 public constant solution =
        44951118505582034238842936837745274349937753370161196589544078244217022840832;

    mapping(address => bool) public solved;

    function solve(
        IKey sand,
        Password p_sand,
        IKey wave,
        Password p_wave,
        IKey shadow,
        Password p_shadow,
        uint256 witness1,
        uint256 witness2,
        uint256 witness3,
        string memory killer,
        string memory victim
    ) external {
        solve(sand, p_sand);
        solve(wave, p_wave);
        solve(shadow, p_shadow);

        uint256 $sand = sand.into();
        uint256 $wave = wave.into();
        uint256 $shadow = shadow.into();
        uint256 $w1 = witness1;
        uint256 $w2 = witness2;
        uint256 $w3 = witness3;

        unchecked {
            require($w1 * $w2 * $w3 > 0);
            require($sand != $wave);
            require($wave != $shadow);
            require($shadow != $sand);
            require($sand ** $w1 > 0);
            require($wave ** $w2 > 0);
            require($w3 ** $shadow > 0);
            require($sand ** $w1 + $wave ** $w2 == $w3 ** $shadow);
        }

        require(keccak256(bytes(string.concat(killer, victim))) == hash);

        solved[msg.sender] = true;
    }

    function generate(address seed) external pure returns (uint256 ret) {
        assembly {
            ret := seed
        }
    }

    function verify(uint256 _start, uint256 _solution) external view returns (bool) {
        require(_solution == solution);
        return solved[address(uint160(_start))];
    }
}

type Password is bytes32;

interface IKey {
    /// MUST return the magic `.selector` on success
    /// MUST check if `owner` is the real owner of the contract
    function SolveThePuzzleOfCoastWithImpressionInNightAndSquallOnCayAndEndToVictory(address owner, Password password)
        external
        view
        returns (bytes4);
}

function into(IKey a) pure returns (uint256 u) {
    assembly {
        u := a
    }
}

using {into} for IKey;

function solve(IKey key, Password password) view {
    require(
        key.SolveThePuzzleOfCoastWithImpressionInNightAndSquallOnCayAndEndToVictory({
            owner: msg.sender,
            password: password
        }) ==
        IKey.SolveThePuzzleOfCoastWithImpressionInNightAndSquallOnCayAndEndToVictory.selector
    );
}
