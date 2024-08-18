// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "curta/interfaces/IPuzzle.sol";

// Hello, it's me your Doordash shopper. I'm at the grocery store.
// I'm having trouble finding the ingredients you requested for your fruit punch.
// Can you help me find them?
// There's only 906459278810089239264754550292645448950 places to check...shouldn't be so bad.
//
// Enjoy this kind of challenge? Consider working at Zellic: jobs@zellic.io
//
contract Chal is IPuzzle {
    uint256 constant punch =
        906_459_278_810_089_239_293_436_146_013_992_401_709;

    function name() external pure returns (string memory) {
        return "Groovy Fruit (Punch) Fiesta";
    }

    function generate(address _seed) external pure returns (uint256) {
        uint256 fiesta = uint256(keccak256(abi.encodePacked(_seed))) % punch;
        fiesta =
            (fiesta % 10_000_000_000_000_000_000_000) +
            10_000_000_000_000_000_000_000;
        return fiesta;
    }

    function verify(
        uint256 _start,
        uint256 _solution
    ) external pure returns (bool) {
        uint256 apple = _solution & 0x7fffffffffffffffffffffffffffffff;
        uint256 banana = (_solution >> 128) &
            0x7fffffffffffffffffffffffffffffff;
        uint256 cherry = 1;

        if (apple < 100 || banana < 100) {
            return false;
        }
        if (smoothie(apple, banana) != 1) {
            return false;
        }
        return
            _start ==
            (((apple * milkshake(banana + cherry)) % punch) +
                ((banana * milkshake(apple + cherry)) % punch) +
                ((cherry * milkshake(apple + banana)) % punch)) %
                punch;
    }

    function milkshake(uint256 apple) private pure returns (uint256) {
        int256 appleJuice_;
        (, appleJuice_, ) = blender(apple, punch);
        require(appleJuice_ > 0);
        uint256 appleJuice = uint256(appleJuice_);
        require((apple * appleJuice) % punch == 1);
        return ((appleJuice % punch) + punch) % punch;
    }

    function blender(
        uint256 apple,
        uint256 banana
    )
        private
        pure
        returns (uint256 yummy, int256 appleJuice, int256 bananaJuice)
    {
        if (banana == 0) {
            return (apple, 1, 0);
        }
        (uint256 _yummy, int256 _appleJuice, int256 _bananaJuice) = blender(
            banana,
            apple % banana
        );
        (yummy, appleJuice, bananaJuice) = (
            _yummy,
            _bananaJuice,
            _appleJuice - int256(apple / banana) * _bananaJuice
        );
    }

    function smoothie(
        uint256 apple,
        uint256 banana
    ) private pure returns (uint256 yummy) {
        (yummy, , ) = blender(apple, banana);
    }
}
