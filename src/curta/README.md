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
> The solution file doesn't have to be named `Solution.t.sol`&mdash;all test files named `*.t.sol` inside `test/curta` are ignored by Git (see [`.gitignore`](../../.gitignore#L28-L29)).

> [!TIP]
> See [`test/curta/example/1/Solution.t.sol`](../../test/curta/example/1/Solution.t.sol) as an example solution.

### Verifying solutions

To verify a solution for 1 puzzle, run the following command:

```sh
forge test --match-path "test/curta/${NETWORK}/${ID}"
```

To verify all your solutions at once, run the following command:

```sh
forge test --match-path "test/curta/*"
```

To verify solutions that require forking, create a file named `.env` at the root of the project and copy the contents of [`.env.sample`](../../.env.sample). After you've filled out the variables, add the `-f $NETWORK` option to the verification command.

> [!NOTE]
> Huff puzzles require the options `--evm-version="shanghai" --ffi` to be set.

### Ethereum

Puzzles were originally added to Curta on Ethereum at [`0x0000000006bC8D9e5e9d436217B88De704a9F307`](https://etherscan.io/address/0x0000000006bC8D9e5e9d436217B88De704a9F307).

| ID                                        | Source                         | Solution set-up                                                    | Requires forking | Write-up                                                                                                          |
| ----------------------------------------- | ------------------------------ | ------------------------------------------------------------------ | ---------------- | ----------------------------------------------------------------------------------------------------------------- |
| [**1**](https://curta.wtf/puzzle/eth:1)   | [`src/curta/eth/1`](./eth/1)   | [`test/curta/eth/1/Setup.sol`](../../test/curta/eth/1/Setup.sol)   | ❌               | [Link](https://curta.wtf/puzzle/eth:1/write-up)                                                                   |
| [**2**](https://curta.wtf/puzzle/eth:2)   | [`src/curta/eth/2`](./eth/2)   | [`test/curta/eth/2/Setup.sol`](../../test/curta/eth/2/Setup.sol)   | ❌               | [Link](https://curta.wtf/puzzle/eth:2/write-up)                                                                   |
| [**3**](https://curta.wtf/puzzle/eth:3)   | [`src/curta/eth/3`](./eth/2)   | [`test/curta/eth/3/Setup.sol`](../../test/curta/eth/3/Setup.sol)   | ❌               | [Link](https://curta.wtf/puzzle/eth:3/write-up)                                                                   |
| [**4**](https://curta.wtf/puzzle/eth:4)   | [`src/curta/eth/4`](./eth/2)   | [`test/curta/eth/4/Setup.sol`](../../test/curta/eth/4/Setup.sol)   | ❌               | [Link](https://curta.wtf/puzzle/eth:4/write-up)                                                                   |
| [**5**](https://curta.wtf/puzzle/eth:5)   | N/A                            | N/A                                                                | N/A              | N/A                                                                                                               |
| [**6**](https://curta.wtf/puzzle/eth:6)   | [`src/curta/eth/6`](./eth/6)   | [`test/curta/eth/6/Setup.sol`](../../test/curta/eth/6/Setup.sol)   | ❌               | [Link](https://curta.wtf/puzzle/eth:6/write-up)                                                                   |
| [**7**](https://curta.wtf/puzzle/eth:7)   | [`src/curta/eth/7`](./eth/7)   | [`test/curta/eth/7/Setup.sol`](../../test/curta/eth/7/Setup.sol)   | ❌               | None                                                                                                              |
| [**8**](https://curta.wtf/puzzle/eth:8)   | [`src/curta/eth/8`](./eth/8)   | [`test/curta/eth/8/Setup.sol`](../../test/curta/eth/8/Setup.sol)   | ❌               | [Link](https://x.com/i/status/1651346013792227332)                                                                |
| [**9**](https://curta.wtf/puzzle/eth:9)   | [`src/curta/eth/9`](./eth/9)   | [`test/curta/eth/8/Setup.sol`](../../test/curta/eth/9/Setup.sol)   | ❌               | [Link](https://github.com/clabby/curta-puzzle/blob/8fbfb95db1f5fa90911246aa177b153e04dffba5/test/Challenge.t.sol) |
| [**10**](https://curta.wtf/puzzle/eth:10) | [`src/curta/eth/10`](./eth/10) | [`test/curta/eth/10/Setup.sol`](../../test/curta/eth/10/Setup.sol) | ❌               | [Link](https://x.com/i/status/1658930303019122688)                                                                |
| [**11**](https://curta.wtf/puzzle/eth:11) | WIP                            | WIP                                                                | WIP              | [Link](https://github.com/leonardoalt/baby_its_me/tree/ce6de115dda28ff5357f1dfa99f4e724a18b9b29/solution)         |
| [**12**](https://curta.wtf/puzzle/eth:12) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1664026474813489153)                                                                |
| [**13**](https://curta.wtf/puzzle/eth:13) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1678260264893026305)                                                                |
| [**14**](https://curta.wtf/puzzle/eth:14) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1683203592344473601)                                                                |
| [**15**](https://curta.wtf/puzzle/eth:15) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1688247687613743105)                                                                |
| [**16**](https://curta.wtf/puzzle/eth:16) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1694746398326128777)                                                                |
| [**17**](https://curta.wtf/puzzle/eth:17) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/eth:17/write-up)                                                                  |
| [**18**](https://curta.wtf/puzzle/eth:18) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1706029458275119205)                                                                |
| [**19**](https://curta.wtf/puzzle/eth:19) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1727198251852636467)                                                                |
| [**20**](https://curta.wtf/puzzle/eth:20) | WIP                            | WIP                                                                | WIP              | [Link](https://x.com/i/status/1728482477965213760)                                                                |
| [**21**](https://curta.wtf/puzzle/eth:21) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/eth:21/write-up)                                                                  |
| [**22**](https://curta.wtf/puzzle/eth:22) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/eth:22/write-up)                                                                  |

### Base

Puzzles were originally added to Curta on Base at [`0x00000000d1329c5cd5386091066d49112e590969`](https://basescan.org/address/0x00000000d1329c5cd5386091066d49112e590969).

| ID                                       | Source                         | Solution set-up                                                    | Requires forking | Write-up                                         |
| ---------------------------------------- | ------------------------------ | ------------------------------------------------------------------ | ---------------- | ------------------------------------------------ |
| [**1**](https://curta.wtf/puzzle/base:1) | [`src/curta/base/1`](./base/1) | [`test/curta/base/1/Setup.sol`](../../test/curta/base/1/Setup.sol) | ❌               | [Link](https://curta.wtf/puzzle/base:1/write-up) |
| [**2**](https://curta.wtf/puzzle/base:2) | [`src/curta/base/2`](./base/2) | [`test/curta/base/2/Setup.sol`](../../test/curta/base/2/Setup.sol) | ❌               | [Link](https://curta.wtf/puzzle/base:2/write-up) |
| [**3**](https://curta.wtf/puzzle/base:3) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/base:3/write-up) |
| [**4**](https://curta.wtf/puzzle/base:4) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/base:4/write-up) |
| [**5**](https://curta.wtf/puzzle/base:5) | WIP                            | WIP                                                                | WIP              | None                                             |
| [**6**](https://curta.wtf/puzzle/base:6) | WIP                            | WIP                                                                | WIP              | None                                             |
| [**7**](https://curta.wtf/puzzle/base:7) | WIP                            | WIP                                                                | WIP              | [Link](https://curta.wtf/puzzle/base:7/write-up) |
| [**8**](https://curta.wtf/puzzle/base:8) | WIP                            | WIP                                                                | WIP              | None                                             |
