# Curta Instructions

[**Website**](https://curta.wtf) - [**Docs**](https://curta.wtf/docs) - [**𝕏**](https://x.com/curta_ctf)

[**Curta Puzzles**](https://curta.wtf/docs/puzzles/overview) is CTF protocol, where players create and solve EVM puzzles to earn NFTs.

## Solving

To solve locally, create a file named `Solution.t.sol` at `test/curta/{network}/{id}` and create a Foundry test contract that imports the set-up contract and implement `test_solve`. Make sure to replace `REPLACE_WITH_YOUR_ADDRESS` with your address:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Setup} from "./Setup.sol";

contract Solution is Setup(REPLACE_WITH_YOUR_ADDRESS) {
    function test_solve() public virtual override {
        // <<<<<<< SOLUTION START.
        uint256 solution;
        // >>>>>>> SOLUTION END.
        vm.prank(solver);
        curta.solve({_puzzleId: puzzleId, _solution: solution});
    }
}
```

To set up solution files for all puzzles, run the following helper script from the root of the repo (won't overwrite anything):

```sh
source script/curta/setup.sh
```

> [!NOTE]
> The solution file doesn't have to be named `Solution.t.sol`&mdash;all test files named `*.t.sol` inside `test/curta` are ignored by Git (see [`.gitignore`](../../.gitignore#L28)).

### Verifying solutions

To verify a solution for 1 puzzle, run the following command:

```sh
forge test --match-path "test/curta/${NETWORK}/${ID}"
```

To verify all your solutions at once, run the following command:

```sh
forge test --match-path "test/curta/*"
```

### Ethereum

Puzzles were originally added to Curta on Ethereum at [`0x0000000006bC8D9e5e9d436217B88De704a9F307`](https://etherscan.io/address/0x0000000006bC8D9e5e9d436217B88De704a9F307).

| ID  | Source                       | Solution set-up                                                  | Requires forking | Write-up                                        |
| --- | ---------------------------- | ---------------------------------------------------------------- | ---------------- | ----------------------------------------------- |
| 1   | [`src/curta/eth/1`](./eth/1) | [`test/curta/eth/1/Setup.sol`](../../test/curta/eth/1/Setup.sol) | ❌               | [Link](https://curta.wtf/puzzle/eth:1/write-up) |

### Base

Puzzles were originally added to Curta on Base at [`0x00000000d1329c5cd5386091066d49112e590969`](https://basescan.org/address/0x00000000d1329c5cd5386091066d49112e590969).
