// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

/**
 *                        ()                        ^^                  - (     )-
 *                        |                                         v    ' / | \ `
 *                   //****\\            .
 *           =======//  * * \\======                     <
 *         ///===\ //\\____//  ===\\\            .                       ^      ^
 *        |||     \|         |/    \\\
 *        |||      |  O---O  |      \\\___....                   .          .           .
 *        |||      |    -    |       \\\///oo///=-=-=-*>*>*>
 *        X|X      |         |        XX|X===////''                 : '     (     ` /
 *       ()||\     |  O---O  |           ^^^^     _________           *   _|
 *       | /  \  //    /\    \\                  | o o o o |         **__/||\_
 *                \\    \ \    \\     ____       | o o o o |___      ** O  O  |
 *                 \\   \  \   ||    |o  o|  /|==| o o o o | - |____ |  O  O  |
 *                  || ||   \  ||    |o  o| /=|  | o o o o | - | == ||  O  O  |
 *                 /_____\  /_____\  |    |/  |  | o ||| o |   |  = ||  |^|^| |\
 *
 *             Elohim: The Fifth Impact
 *     =====================================
 *
 *     In the looming shadow of impending annihilation, humanity confronts an unparalleled menace
 *     — the Elohim.  These warrior angels wield weapons of insurmountable destruction and can
 *     communicate with their hive through their ethereal antennae. A single Elohim scout has
 *     arrived on Earth signaling the ominous advance of an entire fleet, poised to unleash the
 *     cataclysmic Fifth Impact upon our world.
 *
 *     From the depths of NERV Command, a beacon of hope emerges: Eva Units Seven, Eight, Nine,
 *     and Ten. These quantum-linked marvels of technology, can synchronize under the command of a
 *     single pilot.
 *
 *     Now the destiny of Tokyo-3 and all of Earth hinges upon you, pilot.
 *
 *     Can you master the four Evas, quell the Elohim threat, and unlock their DNA sequence to
 *     halt the impending invasion?
 *
 *     In this climactic clash of unity and chaos, where humanity's essence is laid bare, the
 *     moment has arrived to brave the unknown. Are you prepared to become the savior, our final
 *     hope in the darkest hour?
 *
 *     The Fifth Impact looms, and the ultimate battle ignites.
 */

contract Puzzle is IPuzzle {
    error QuantumOpcodeError(bytes1 opcode);

    address public NERV;
    address internal impl;
    address internal immutable addressThis;
    address internal immutable owner;

    constructor(address nerv_) {
        NERV = nerv_;
        impl = address(this);
        addressThis = address(this);
        owner = msg.sender;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //                              CORE PILOT FUNCTIONS                                  //
    ////////////////////////////////////////////////////////////////////////////////////////

    function name() external pure returns (string memory) {
        return "Elohim";
    }

    /// @dev This function returns the pilot's account address.
    function generate(address _seed) external pure returns (uint256) {
        return uint160(_seed);
    }

    function verify(uint256 pilotAddress, uint256 input) external view returns (bool worldSaved) {
        return Puzzle(impl)._verify(pilotAddress, input);
    }

    function _verify(uint256 pilotAddress, uint256 input) external view returns (bool worldSaved) {
        /******************************* input ***************************************************
         **   | Evangelion                             | Eva    | Elohim DNA   | Simulator      **
         **   | Control Address                        | Config | Prediction   | Difficulty     **
         ** 0x 00112233445566778899AABBCCDDEEFF00112233 A1A2A3A3 AAAAAAAAAAAAAA 18              **
         *****************************************************************************************/
        require(msg.sender == addressThis, "ser, this is a wendy's");
        address pilot = address(uint160(pilotAddress));

        /** Simulator Difficulty */
        uint8 difficulty = uint8(input);
        _validateSimulatorDifficulty(difficulty, pilot);

        /** Elohim DNA
        It's up to you to develop an algorithm that can predict the Elohim's DNA sequence in
        advance. If you can do it, we can develop genetic weaponry to take on the invaders and
        we just might have a chance at saving the world. */
        uint56 dnaVerification = uint56(uint256(input >> 8));

        /** Eva Config
        The Eva configuration is based on a combination of the pilot's DNA and time-dependent
        environmental factors. These settings must be used in the submitted input, pilot. */
        uint256 config = (input & CONFIG_MASK) >> 64;
        if (generateEvaConfig(pilot, difficulty) != config) revert("invalid eva config");
        uint256[] memory configVals = new uint256[](4);
        for (uint256 idx; idx < 4; ++idx) {
            configVals[idx] = uint8(config >> (3 - idx) * 8);
        }

        /** Evangelion Control Address */
        address solutionAddress = address(uint160((input & ADDRESS_MASK) >> 96));
        _validateEvangelionControlProtocol(solutionAddress, difficulty); /**


                        ██████████████████████████████████████████████
                        █░░░░░░█████████░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
                        █░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
                        █░░▄▀░░█████████░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
                        █░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░█████████
                        █░░▄▀░░█████████░░▄▀░░░░░░░░░░█░░▄▀░░█████████
                        █░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░░░░░█
                        █░░▄▀░░█████████░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░█
                        █░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░██░░▄▀░░█
                        █░░▄▀░░░░░░░░░░█░░▄▀░░█████████░░▄▀░░░░░░▄▀░░█
                        █░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█
                        █░░░░░░░░░░░░░░█░░░░░░█████████░░░░░░░░░░░░░░█
                        ██████████████████████████████████████████████
                                     Defeat the Elohim

        You're cleared to establish Eva-link with NERV Command...
        This is it pilot -- good luck and God speed! */
        (uint256 s2EngineCheck, uint256 dnaSampled) = callNERVCommand(solutionAddress, configVals, difficulty);


        // Post-op S2 Engine integrity check
        _superSolenoidEngineCheck(s2EngineCheck, difficulty);


        // Are ya winning, son?
        worldSaved = dnaSampled == dnaVerification;
    }

    // Syncing with an Evangelion is a delicate process.
    // Configuration settings are based on the pilot's DNA and temporal environment factors.
    // All configuration settings must be valid quantum values -- 0x69 is sacred.
    function generateEvaConfig(address _seed, uint8 difficulty) public view returns (uint256 actualSeed) {
        uint256 adjustedBlock;
        if (difficulty == DIFFICULTY_LEVEL_HARD) adjustedBlock = block.number >> 7;
        if (difficulty == DIFFICULTY_LEVEL_INSANE) adjustedBlock = block.number >> 5;
        if (difficulty == DIFFICULTY_LEVEL_IMPOSSIBLE) adjustedBlock = block.number >> 3;
        if (difficulty == DIFFICULTY_LEVEL_CHAINLIGHT) adjustedBlock = block.number;

        uint32 hash = uint32(bytes4(keccak256(abi.encodePacked(_seed, adjustedBlock))));

        uint256 val;
        uint256 shiftAmount;
        for (uint256 idx; idx < 4; ++idx) {
            shiftAmount = (3 - idx) * 8;
            val = uint8(hash >> shiftAmount);
            if (val <= 0x1 || !_isValidQuantumValue(bytes1(uint8(val)), difficulty)) {
                val = 0x69;
            }
            actualSeed |= (val << shiftAmount);
        }
    }

   function callNERVCommand(address solutionAddress, uint256[] memory configVals, uint8 difficulty)
        public
        view
        returns (uint256 s2EngineCheck, uint256 dnaSampled)
    {
        /**
                                     __ _._.,._.__
                                .o8888888888888888P'
                                .d88888888888888888K
                ,8            888888888888888888888boo._
                :88b           888888888888888888888888888b.
                `Y8b          88888888888888888888888888888b.
                    `Yb.       d8888888888888888888888888888888b
                    `Yb.___.88888888888888888888888888888888888b
                        `Y888888888888888888888888888888CG88888P"'
                        `88888888888888888888888888888MM88P"'
        "Y888K    "Y8P""Y888888888888888888888888oo._""""
        88888b    8    8888`Y88888888888888888888888oo.
        8"Y8888b  8    8888  ,8888888888888888888888888o,
        8  "Y8888b8    8888""Y8`Y8888888888888888888888b.
        8    "Y8888    8888   Y  `Y8888888888888888888888
        8      "Y88    8888     .d `Y88888888888888888888b
        .d8b.      "8  .d8888b..d88P   `Y88888888888888888888
                                        `Y88888888888888888b.
                        "Y888P""Y8b. "Y888888888888888888888
                            888    888   Y888`Y888888888888888
                            888   d88P    Y88b `Y8888888888888
                            888"Y88K"      Y88b dPY8888888888P
                            888  Y88b       Y88dP  `Y88888888b
                            888   Y88b       Y8P     `Y8888888
                        .d888b.  Y88b.      Y        `Y88888
                                                        `Y88K
                                                            `Y8*/

        (bool success, bytes memory data) = address(NERV).staticcall(
            abi.encode(
                solutionAddress,
                configVals[0],
                configVals[1],
                configVals[2],
                configVals[3],
                difficulty
            )
        );
        require(success, "link interrupted");
        uint256 dnaSampledFull;
        (s2EngineCheck, dnaSampledFull) = abi.decode(data, (uint256, uint256));
        dnaSampled = uint56(dnaSampledFull);
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //                                  VALIDATIONS                                       //
    ////////////////////////////////////////////////////////////////////////////////////////

    function _validateSimulatorDifficulty(uint8 difficulty, address pilot) internal pure {
        /** There are 4 levels of difficulty that pilots can choose when entering the simulator:

        0x01 - HARD
        0x02 - INSANE
        0x03 - IMPOSSIBLE
        0x18 - CHAINLIGHT

        Pilot ranked #1 on the Curta leaderboard must select CHAINLIGHT
        Pilots ranked #2-#10 on the Curta leaderboard must select at least level IMPOSSIBLE
        Pilots ranked #11-#25 must select at least difficulty level INSANE
        All other pilots must select at least difficulty level HARD

        Warning: Choosing the CHAINLIGHT difficulty means engaging in a live battle with the
        Elohim. The number one rank on the leaderboard is required to engage in this mode, but
        anyone brave enough can also try. Evangelions lost in this mode CANNOT be revived.

        Choose your difficulty by setting the lowest byte of the solution to the desired difficulty
        level. Choosing a higher difficulty is guaranteed to bring you untold fame, new friends,
        and increased chances of finding a girlfriend. */

        bool valid;
        if (_isLeadeboardTopDog(pilot)) {
            valid = difficulty == DIFFICULTY_LEVEL_CHAINLIGHT;
        } else if (_isLeaderboardTop10(pilot)) {
            valid = _isDifficultyImpossibleOrHigher(difficulty);
        } else if (_isLeaderboardTop25(pilot)) {
            valid = _isDifficultyInsaneOrHigher(difficulty);
        } else {
            valid = difficulty == DIFFICULTY_LEVEL_HARD || _isDifficultyInsaneOrHigher(difficulty);
        }

        require(valid, "no plebs");  // you're like a pleb in a pillory in lieu of this exposé...
    }

    function _superSolenoidEngineCheck(uint256 s2EngineCheck, uint8 difficulty) internal pure {
        uint solenoidEngineThreshold;
        if (difficulty == DIFFICULTY_LEVEL_CHAINLIGHT) {
            solenoidEngineThreshold = 3748;
        } else if (difficulty == DIFFICULTY_LEVEL_IMPOSSIBLE) {
            solenoidEngineThreshold = 4000;
        } else if (difficulty == DIFFICULTY_LEVEL_INSANE) {
            solenoidEngineThreshold = 4150;
        } else if (difficulty == DIFFICULTY_LEVEL_HARD) {
            solenoidEngineThreshold = 4340;
        }
        require(s2EngineCheck <= solenoidEngineThreshold, "s2 engine failure");
    }

    function _isValidCodeSize(address solution, uint8 difficulty) internal view returns (bool) {
        uint256 maxCodeSize;
        if (difficulty == DIFFICULTY_LEVEL_CHAINLIGHT) {
            maxCodeSize = 189;
        } else if (difficulty == DIFFICULTY_LEVEL_IMPOSSIBLE) {
            maxCodeSize = 222;
        } else if (difficulty == DIFFICULTY_LEVEL_INSANE) {
            maxCodeSize = 300;
        } else if (difficulty == DIFFICULTY_LEVEL_HARD) {
            maxCodeSize = 466;
        }
        return solution.code.length <= maxCodeSize;
    }

    function _isValidQuantumValue(bytes1 opcd, uint8 difficulty) internal pure returns (bool) {
        if (difficulty == DIFFICULTY_LEVEL_CHAINLIGHT) {
            if (opcd == 0x18 || opcd == 0x42 || opcd == 0x44 ||
                opcd == 0x46 || opcd == 0x48) return false;
        }
        if (_isDifficultyImpossibleOrHigher(difficulty)) {
            if (opcd == 0x34 || opcd == 0x33 || opcd == 0x39 ||
                opcd == 0x3f || opcd == 0x40) return false;
        }
        if (_isDifficultyInsaneOrHigher(difficulty)) {
            if (opcd == 0xF1 || opcd == 0xF2 || opcd == 0xF4 ||
            opcd == 0xFa || opcd == 0xFe) return false;
        }
        return !(opcd == 0xf5 || opcd == 0xff);
    }

    function _validateQuantamValues(address solution, uint8 difficulty) internal view {
        bytes memory bts = solution.code;
        for (uint256 idx; idx < bts.length; ++idx) {
            if (!_isValidQuantumValue(bts[idx], difficulty)) revert QuantumOpcodeError(bts[idx]);
        }
    }

    function _isValidAddress(address solution, uint8 difficulty) public pure returns (bool valid) {
        if (difficulty == DIFFICULTY_LEVEL_HARD) {
            uint256 topBit = uint160(solution) >> 159;
            valid = topBit == 1;
        }
        if (difficulty == DIFFICULTY_LEVEL_INSANE) {
            valid = bytes1(bytes20(solution)) == bytes1(uint8(0x69));
        }
        if (difficulty == DIFFICULTY_LEVEL_IMPOSSIBLE) {
            valid = bytes2(bytes20(solution)) == bytes2(uint16(0x0420));
        }
        if (difficulty == DIFFICULTY_LEVEL_CHAINLIGHT) {
            valid = bytes3(bytes20(solution)) == bytes3(uint24(0x181818));
        }
    }

    function _validateEvangelionControlProtocol(address solution, uint8 difficulty) internal view {
        /** You're not a rookie any more, pilot.

        Runtime gas limits, bytecode size restraints, opcode restrictions, and vanity addresses are
        just par for the course. Let's do this and get on the battle field. */
        require(_isValidAddress(solution, difficulty), "mining failure");
        require(_isValidCodeSize(solution, difficulty), "too long! twss");
        _validateQuantamValues(solution, difficulty);
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //                                  UTILITIES                                         //
    ////////////////////////////////////////////////////////////////////////////////////////

    function _isLeadeboardTopDog(address addr) internal pure returns (bool) {
        return addr == LEADERBOARD_1_ADDRESS;
    }

    function _isLeaderboardTop10(address addr) internal pure returns (bool) {
        return addr == LEADERBOARD_2_ADDRESS || addr == LEADERBOARD_3_ADDRESS ||
               addr == LEADERBOARD_4_ADDRESS || addr == LEADERBOARD_5_ADDRESS ||
               addr == LEADERBOARD_6_ADDRESS || addr == LEADERBOARD_7_ADDRESS ||
               addr == LEADERBOARD_8_ADDRESS || addr == LEADERBOARD_9_ADDRESS ||
               addr == LEADERBOARD_10_ADDRESS;
    }

    function _isLeaderboardTop25(address addr) internal pure returns (bool) {
        return addr == LEADERBOARD_11_ADDRESS || addr == LEADERBOARD_12_ADDRESS ||
               addr == LEADERBOARD_13_ADDRESS || addr == LEADERBOARD_14_ADDRESS ||
               addr == LEADERBOARD_15_ADDRESS || addr == LEADERBOARD_16_ADDRESS ||
               addr == LEADERBOARD_17_ADDRESS || addr == LEADERBOARD_18_ADDRESS ||
               addr == LEADERBOARD_19_ADDRESS || addr == LEADERBOARD_20_ADDRESS ||
               addr == LEADERBOARD_21_ADDRESS || addr == LEADERBOARD_22_ADDRESS ||
               addr == LEADERBOARD_23_ADDRESS || addr == LEADERBOARD_24_ADDRESS ||
               addr == LEADERBOARD_25_ADDRESS;
    }

    function _isDifficultyImpossibleOrHigher(uint8 difficulty) internal pure returns (bool) {
        return difficulty == DIFFICULTY_LEVEL_IMPOSSIBLE ||
               difficulty == DIFFICULTY_LEVEL_CHAINLIGHT;
    }

    function _isDifficultyInsaneOrHigher(uint8 difficulty) internal pure returns (bool) {
        return difficulty == DIFFICULTY_LEVEL_INSANE ||
                               _isDifficultyImpossibleOrHigher(difficulty);
    }


    ////////////////////////////////////////////////////////////////////////////////////////
    //                                STATIC VALUES                                       //
    ////////////////////////////////////////////////////////////////////////////////////////

    uint256 constant ADDRESS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;
    uint256 constant CONFIG_MASK = 0x0000000000000000000000000000000000000000FFFFFFFF0000000000000000;
    uint256 constant ANSWER_MASK = 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFF00;

    uint8 constant DIFFICULTY_LEVEL_HARD = 0x1;
    uint8 constant DIFFICULTY_LEVEL_INSANE = 0x2;
    uint8 constant DIFFICULTY_LEVEL_IMPOSSIBLE = 0x3;
    uint8 constant DIFFICULTY_LEVEL_CHAINLIGHT = 0x18; // 퍼즐 난이도 18이라니, 대박! 화이팅!

    address constant LEADERBOARD_1_ADDRESS = 0xB49bf876BE26435b6fae1Ef42C3c82c5867Fa149; // chainlight.io
    address constant LEADERBOARD_2_ADDRESS = 0x6E82554d7C496baCcc8d0bCB104A50B772d22a1F; // minimooger.eth
    address constant LEADERBOARD_3_ADDRESS = 0x4a69B81A2cBEb3581C61d5087484fBda2Ed39605; // jinu.eth
    address constant LEADERBOARD_4_ADDRESS = 0x14869c6bF40BBc73e45821F7c28FD792151b3f9A; // igorline.eth
    address constant LEADERBOARD_5_ADDRESS = 0x0Fc363b52E49074a395B075a6814Cb8F37E8F8BE; // p0pular.eth
    address constant LEADERBOARD_6_ADDRESS = 0xBDfeB5439f5daecb78A17Ff846645A8bDBbF5725; // datadanne.eth
    address constant LEADERBOARD_7_ADDRESS = 0x2de14DB256Db2597fe3c8Eed46eF5b20bA390823; // eoa.sina.eth
    address constant LEADERBOARD_8_ADDRESS = 0xB95777719Ae59Ea47A99e744AfA59CdcF1c410a1; // 0xcacti.eth
    address constant LEADERBOARD_9_ADDRESS = 0xd4057e08B9d484d70C5977784fC1f6D82d45ff67; // kalzak.eth
    address constant LEADERBOARD_10_ADDRESS = 0x97735C60c5E3C2788b7EE570306775e687095D19; // plotchy.eth
    address constant LEADERBOARD_11_ADDRESS = 0x4790c165A2c4B37527B56ac7772B792912C46329;
    address constant LEADERBOARD_12_ADDRESS = 0x0DEdcE798692E8C668d67e430151106aBC9ABCe1; // ngndev.eth
    address constant LEADERBOARD_13_ADDRESS = 0x433EA2df6D7c567B1Dd55e3FB99512222Cb23d95; // ragepit.eth
    address constant LEADERBOARD_14_ADDRESS = 0x79d31bFcA5Fda7A4F15b36763d2e44C99D811a6C; // horsefacts.eth
    address constant LEADERBOARD_15_ADDRESS = 0x0165f91FAF9EDeb9C5817c7a3c92110aa5329BeA; // pa-tate.eth
    address constant LEADERBOARD_16_ADDRESS = 0x58593392d72A9D90b133e1C8ecEec581C354687f; // sampriti.eth
    address constant LEADERBOARD_17_ADDRESS = 0x03433830468d771A921314D75b9A1DeA53C165d7; // karmafacts.eth
    address constant LEADERBOARD_18_ADDRESS = 0x79635b386B9bd6636Cd701879C32E6dd181C853F; // vicnaum.eth
    address constant LEADERBOARD_19_ADDRESS = 0x6b756b6905A07be65FD59b50e58dD4C965C32500;
    address constant LEADERBOARD_20_ADDRESS = 0x9470Ab9c3aAc221A57e94F522659D4327C5EAdEd; // sileo.eth
    address constant LEADERBOARD_21_ADDRESS = 0x5f71a197D303Cd700511323976067ECe43dE8AD0; // shung.crypto-frens.eth
    address constant LEADERBOARD_22_ADDRESS = 0x5DFfD5527551888c2AC47f799c4Dc8e830dECeE7; // sina.eth
    address constant LEADERBOARD_23_ADDRESS = 0xC6868e56b7BeCd885102fdaF33137F1712Bcf1d7; // 0xkitetsu.eth
    address constant LEADERBOARD_24_ADDRESS = 0x7976B5A96Dc857309498E8Ab0d342117c7C9e6c5; // adamegyed.eth
    address constant LEADERBOARD_25_ADDRESS = 0x286cD2FF7Ad1337BaA783C345080e5Af9bBa0b6e; // forager.eth

    ////////////////////////////////////////////////////////////////////////////////////////
    //                         NERV COMMAND SECURITY CLEARANCE REQUIRED                   //
    ////////////////////////////////////////////////////////////////////////////////////////

    function setNERV(address nerv_) external {
        require(msg.sender == owner);
        NERV = nerv_;
    }
    function properRug(address newImpl) external {
        require(msg.sender == owner);
        impl = newImpl;
    }
}
