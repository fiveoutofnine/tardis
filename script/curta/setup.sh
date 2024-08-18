# Helper function to create solution files for Curta puzzles.
create_file() {
    local id="$1"
    local base_dir="$2"
    local setup_path="${base_dir}/${id}/Setup.sol"
    local file_path="${base_dir}/${id}/Solution.t.sol"

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

contract Solution is Setup {
    function test_solve() public {
        // SOLUTION GOES HERE.
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
    create_file "$id" "test/curta/base"
    create_file "$id" "test/curta/eth"
done
