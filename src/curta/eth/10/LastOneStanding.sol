// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IPuzzle} from "curta/interfaces/IPuzzle.sol";

/// @title Last One Standing
/// @custom:subtitle 4 × 4 Chess Puzzle.
/// @author fiveoutofnine
/// @notice The goal of the puzzle is to make a series of moves such that only
/// the white king remains on the board. Each move must capture another piece,
/// and the black king may be captured. Checks do not matter, but the white king
/// can not be captured by any black piece. The starting position must have
/// all the pieces a standard game of chess has, except for the pawns.
contract Chess is IPuzzle {
    // -------------------------------------------------------------------------
    // Pieces
    // -------------------------------------------------------------------------
    // Let `pieceType` be `piece & 7` (i.e. the last 3 bits). Then, the
    // formulation below allows for the following checks:
    //     * `(pieceType & 3) == 1` is only true for kings and knights;
    //       equivalently, if `!= 1`, the piece must be a sliding piece.
    //     * A knight must move 2 squares in one direction and 1 square in the
    //       other direction. The square of these is 5 (`2**2 + 1**2`), and
    //       there are no other pair of numbers whose squares sum to 5. This
    //       gives rise to a very nice way to validate knight moves:
    //       `xDiff * xDiff + yDiff * yDiff == pieceType` is valid if and only
    //       if the move is made by a knight.
    //     * Unlike knights, kings have multiple "sum of squares" values: (1) a
    //       king may move 0 in 1 direction and 0 in another
    //       (`0**2 + 1**2 = 1`), or (2) a king may move 1 in both directions
    //       (`1**2 + 1**2 = 2`). If we wrap
    //       `xDiff * xDiff + yDiff * yDiff - pieceType` in an `unchecked`
    //       block, we can check for both of these conditions at once if we
    //       denote 1 as king: the expression will evaluate to 0 or 1 if the
    //       move is valid (note: we make use of the fact that underflows result
    //       in a number larger than 1). Since 6 (1 more than the value assigned
    //       for knights (5)) also has no other pair of numbers whose squares
    //       sum to it, we can extend this logic to knights! Conclusion: as
    //       long as we check the condition in a block where we know the piece
    //       is a king or a knight, we can validate the move with 1 expression.

    /// @notice Denotes an empty square.
    uint256 private constant EMPTY = 0;

    /// @notice Denotes a black king.
    uint256 private constant KING = 1;

    /// @notice Denotes a black bishop.
    uint256 private constant BISHOP = 2;

    /// @notice Denotes a black rook.
    uint256 private constant ROOK = 3;

    /// @notice Denotes a black queen.
    uint256 private constant QUEEN = 4;

    /// @notice Denotes a black knight.
    uint256 private constant KNIGHT = 5;

    /// @notice Denotes a white king.
    uint256 private constant WHITE_KING = (1 << 3) | KING;

    /// @notice Denotes a white bishop.
    uint256 private constant WHITE_BISHOP = (1 << 3) | BISHOP;

    /// @notice Denotes a white rook.
    uint256 private constant WHITE_ROOK = (1 << 3) | ROOK;

    /// @notice Denotes a white queen.
    uint256 private constant WHITE_QUEEN = (1 << 3) | QUEEN;

    /// @notice Denotes a white knight.
    uint256 private constant WHITE_KNIGHT = (1 << 3) | KNIGHT;

    // -------------------------------------------------------------------------
    // Moves
    // -------------------------------------------------------------------------
    // The following are masks to extract pieces relevant to some ray a sliding
    // piece traverses. If a piece is a sliding piece, the bits we retrieve by
    // masking the board shifted to the smaller index of the move and the
    // corresponding ray's mask should be 0 (i.e. there are no pieces in)
    // the way.
    //            | Ray Type                   | Mask               |
    //            |----------------------------+--------------------|
    //            | Vertical                   | 0xF000F000F000F    |
    //            | Horizontal                 | 0xFFFF             |
    //            | Diagonal towards top-right | 0xF00F00F00F       |
    //            | Diagonal towards top-left  | 0xF0000F0000F0000F |
    //
    // We can reserve 64 bits for each of the masks, and then bitpack it into
    // a single `uint256`, which will serve as a look-up table for ray check
    // masks:
    // ```
    // uint256 RAY_MASKS = (0xF000F000F000F << 192)
    //     | (0xFFFF << 128)
    //     | (0xF00F00F00F << 64)
    //     | 0xF0000F0000F0000F;
    // ```
    //
    // This eliminates almost all of the branching a naive implementation may
    // require. Let `board` be the position of the board, `minIndex` be the
    // smaller of the move's 2 indices, `rayMask` be the corresponding ray mask,
    // `idxDiff` be the difference between the 2 indices of the move, and
    // `minPiece` be the piece at the smaller of the 2 indices. Then, the
    // general condition for invalidating a sliding piece's move is:
    // ```
    // (board >> (minIndex << 2))
    //     & (rayMask & ((1 << (idxDiff << 2)) - 1)
    // ) != minPiece;
    // ```

    /// @notice A look-up table of ray check masks.
    uint256 private constant RAY_MASKS =
        0xF000F000F000F000000000000FFFF000000F00F00F00FF0000F0000F0000F;

    /// @notice A mask to read a ray mask from `RAY_MASKS`.
    uint256 private constant RAY_MASK_MASK = 0xFFFFFFFFFFFFFFFF;

    // -------------------------------------------------------------------------
    // Game State
    // -------------------------------------------------------------------------

    /// @notice The position of the board, before it is shuffled. There are the
    /// same number of pieces as in a regular game of chess, except for the
    /// pawns.
    /// @dev The expression below evaluates to `0x122334559AABBCDD`.
    uint256 private constant STARTING_BOARD =
        (KING << 60) |
            (BISHOP << 56) |
            (BISHOP << 52) |
            (ROOK << 48) |
            (ROOK << 44) |
            (QUEEN << 40) |
            (KNIGHT << 36) |
            (KNIGHT << 32) |
            (WHITE_KING << 28) |
            (WHITE_BISHOP << 24) |
            (WHITE_BISHOP << 20) |
            (WHITE_ROOK << 16) |
            (WHITE_ROOK << 12) |
            (WHITE_QUEEN << 8) |
            (WHITE_KNIGHT << 4) |
            (WHITE_KNIGHT << 0);

    /// @notice The 65th bit (from the right) indicates whose turn it is to
    /// play: if it is `0`, a black piece must play next; if it is `1`, a white
    /// piece must play next.
    /// @dev The expression below evaluates to `0x10000000000000000`.
    uint256 private constant TURN_MASK = 1 << 64;

    /// @notice A bitpacked integer that serves as a mapping from a piece type
    /// to the count remaining (i.e. has not been captured yet).
    /// @dev The expression below evaluates to `0x9A409A4`:
    ///            Index | 13 12 11 10 09 08 07 06 05 04 03 02 01 00
    ///            ------+------------------------------------------
    ///            Bits  | 10_01_10_10_01_00_00_00_10_01_10_10_01_00
    uint256 private constant STARTING_PIECE_COUNTS = 0x9A409A4;

    /// @notice By the end of the sequence of moves, the piece counts must be
    /// equivalent to this.
    /// @dev The expression below evaluates to `0x40000`: there must only be 1
    /// white king left, so we shift `1` left by `(WHITE_KING << 1)` bits.
    uint256 private constant SOLVED_PIECE_COUNTS = (1 << (WHITE_KING << 1));

    /// @inheritdoc IPuzzle
    function name() external pure returns (string memory) {
        return "Last One Standing";
    }

    /// @inheritdoc IPuzzle
    function generate(address _seed) external pure returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_seed)));
        uint256 puzzle = STARTING_BOARD;

        // We swap until the seed is exhausted; otherwise, vanity addresses may
        // guarantee an easy / trivial solution to the puzzle.
        for (; seed != 0; seed >>= 8) {
            // Retrieve 8 random bits from `seed` to determine which indices to
            // swap.
            uint256 a = seed & 0xF;
            uint256 b = (seed >> 4) & 0xF;
            seed >>= 8;

            // Nothing to swap if the indices are the same.
            if (a == b) continue;

            puzzle = swap(puzzle, a, b);
        }

        // White should play first, so we initialize with `1` at the 65th bit.
        return TURN_MASK | puzzle;
    }

    /// @inheritdoc IPuzzle
    function verify(
        uint256 _start,
        uint256 _solution
    ) external pure returns (bool) {
        uint256 pieceCounts = STARTING_PIECE_COUNTS;

        // Apply `_solution` to `_start`.
        for (; _solution != 0; _solution >>= 8) {
            uint256 from = (_solution >> 4) & 0xF;
            uint256 to = _solution & 0xF;
            uint256 pieceFrom = (_start >> (from << 2)) & 0xF;
            uint256 pieceTo = (_start >> (to << 2)) & 0xF;

            // Sanity checks.
            if (
                pieceFrom == EMPTY || // No piece to move.
                pieceTo == EMPTY || // There must be a piece at the `to`.
                pieceFrom >> 3 != _start >> 64 || // It must be the correct piece's turn.
                pieceFrom >> 3 == pieceTo >> 3 || // Piece must be a capture.
                pieceTo == WHITE_KING // The white king cannot be captured.
            ) return false;

            // Move validation.
            uint256 pieceType = pieceFrom & 7;
            unchecked {
                uint256 xDiff = (to & 3) > (from & 3)
                    ? (to & 3) - (from & 3)
                    : (from & 3) - (to & 3);
                uint256 yDiff = (to >> 2) > (from >> 2)
                    ? (to >> 2) - (from >> 2)
                    : (from >> 2) - (to >> 2);

                if (pieceType & 3 == 1) {
                    // Piece is a knight or a king.
                    if (xDiff * xDiff + yDiff * yDiff - pieceType > 1)
                        return false;
                } else {
                    // Piece is a sliding piece (bishop, rook, or queen).
                    uint256 minIndex;
                    uint256 idxDiff;
                    {
                        if (to > from) {
                            minIndex = from;
                            idxDiff = to - from;
                        } else {
                            minIndex = to;
                            idxDiff = from - to;
                        }
                    }

                    uint256 rayMask;
                    {
                        uint256 isOrthogonal;
                        uint256 isDiagonal;
                        uint256 isVertical;
                        uint256 isDiagonalRight;
                        assembly {
                            // Equivalent to`xDiff * yDiff == 0 && pieceType != BISHOP`.
                            isOrthogonal := and(
                                iszero(mul(xDiff, yDiff)),
                                iszero(eq(pieceType, BISHOP))
                            )
                            // Equivalent to `xDiff != yDiff && pieceType != ROOK`.
                            isDiagonal := and(
                                eq(xDiff, yDiff),
                                iszero(eq(pieceType, ROOK))
                            )
                            // Equivalent to `xDiff == 0`.
                            isVertical := iszero(xDiff)
                            // Equivalent to `idxDiff % 3 == 0`.
                            isDiagonalRight := iszero(mod(idxDiff, 3))
                        }

                        // Piece does not move orthogonally or diagonally.
                        if (isOrthogonal + isDiagonal == 0) return false;

                        // Retrieve the ray mask and correctly size it.
                        rayMask =
                            (((RAY_MASKS >> (isOrthogonal << 7)) >>
                                (isVertical << 6)) >> (isDiagonalRight << 6)) & // `<< 7` is equivalent to `* 128`. // `<< 6` is equivalent to `* 64`. // `<< 6` is equivalent to `* 64`.
                            (RAY_MASK_MASK & ((1 << (idxDiff << 2)) - 1));
                    }

                    // Check if the ray between `from` and `to` is clear.
                    // Shift the board to the index to apply the ray mask.
                    uint256 shiftedBoard;
                    {
                        shiftedBoard = _start >> (minIndex << 2);
                    }
                    if (
                        (shiftedBoard & rayMask) !=
                        (to > from ? pieceFrom : pieceTo)
                    ) return false;
                }
            }

            // Apply move and update turn indicator.
            _start &= ~((0xF << (from << 2)) | (0xF << (to << 2)));
            _start |= pieceFrom << (to << 2);
            _start ^= TURN_MASK;

            // Update `pieces`.
            uint256 mask = 3 << (pieceTo << 1);
            pieceCounts =
                (pieceCounts & ~mask) |
                (((pieceCounts & mask) >> 1) & mask);
        }

        return pieceCounts == SOLVED_PIECE_COUNTS;
    }

    /// @notice A function to swap two pieces on the puzzle.
    /// @param _puzzle The board to swap pieces on.
    /// @param _a The index of the first piece to swap.
    /// @param _b The index of the second piece to swap.
    /// @return The board with the pieces swapped.
    function swap(
        uint256 _puzzle,
        uint256 _a,
        uint256 _b
    ) internal pure returns (uint256) {
        // Adjust board index to number of bits to shift by.
        _a <<= 2; // `<< 2` is equivalent to `* 4`.
        _b <<= 2; // `<< 2` is equivalent to `* 4`.

        // Get pieces at `_a` and `_b`.
        uint256 a = (_puzzle >> _a) & 0xF;
        uint256 b = (_puzzle >> _b) & 0xF;

        // Delete bits.
        _puzzle &= type(uint256).max ^ (0xF << _a);
        _puzzle &= type(uint256).max ^ (0xF << _b);

        // Insert pieces.
        _puzzle |= a << _b;
        _puzzle |= b << _a;

        return _puzzle;
    }
}
