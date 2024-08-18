# Helper function to create solution files for Curta puzzles.
create_file() {
    local network="$1"
    local id="$2"
    local setup_path="test/curta/${network}/${id}/Setup.sol"
    local file_path="test/curta/${network}/${id}/Solution.t.sol"

    # Check if the setup file exists and exit if it doesn't.
    if [ ! -f "$setup_path" ]; then
        return
    fi
    
    # Create the directory if it doesn't exist.
    mkdir -p "$(dirname "$file_path")"
    
    # Check if the file already exists.
    if [ ! -f "$file_path" ]; then
        # Write content to the file.
        cat <<EOF > "$file_path"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Setup} from "./Setup.sol";

/// @dev View the puzzle's source at \`src/curta/$network/$id\`.
contract Solution is Setup {
    function test_solve() public virtual override {
        // <<<<<<< SOLUTION START.
        uint256 solution;
        // >>>>>>> SOLUTION END.
        curta.solve({_puzzleId: $id, _solution: solution});
    }
}
EOF
        echo "CREATED: $file_path"
    else
        echo "SKIPPED: $file_path"
    fi
}

# Create solution files.
for id in {1..100}; do
    create_file "base" "$id"
    create_file "eth" "$id"
done
