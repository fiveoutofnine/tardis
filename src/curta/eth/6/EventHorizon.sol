// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

/**
 * @title Touring-Heisenberg Uncertainty Principle
 * @author wei3erHase
 */
contract EventHorizon is IPuzzle {
    /// @inheritdoc IPuzzle
    string public constant name = "Uncertainty Principle";

    uint256 constant PLANK_CONSTANT = 0x111; // 1 in XYZ
    uint256 constant PLANK_LENGTH = 0xF;
    uint256 constant PHISICAL_SPHERE = type(uint32).max;

    /// @inheritdoc IPuzzle
    function generate(address _seed) external view returns (uint256) {
        return _gammaFn(uint256(uint160(_seed))) | PLANK_CONSTANT;
    }

    /// @inheritdoc IPuzzle
    function verify(
        uint256 _start,
        uint256 _solution
    ) external view returns (bool) {
        uint256 _axis;
        uint256 _momentum;
        uint256 _position;

        unchecked {
            while (_start & PHISICAL_SPHERE > 0) {
                _position = _axis++ * 4;
                _momentum = _gammaFn(_solution) & (PLANK_LENGTH << _position);
                for (uint256 _i; _i < _momentum >> _position; _i++) {
                    continue;
                }
                _start -= _momentum;
            }
        }

        return true;
    }

    function _gammaFn(uint256 _xyz) internal view returns (uint256) {
        /// @notice gasleft() has a directional preference (as entropy)
        return uint256(keccak256(abi.encodePacked(_xyz, gasleft())));
    }
}
