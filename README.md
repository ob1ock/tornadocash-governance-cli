# tornadocash-governance-cli

## wip

https://github.com/ob1ock/tornado-governance-cli

**tornadocash-governance-cli is a set of bash functions that use the forge and cast foundry-rs tools and a corresponding forge test contract to help simulate Tornado Cash governance proposals.**

`tornadocash-governance-cli` consists of:

-   **tornadocash-governance-cli**: A bash script and functions which make use of the foundry-rs `forge`, `cast` tools and foundry test contract.
-   **src/Proposal.t.sol**: A foundry test contract that can simulate locking, proposing, voting and executing Tornado Cash governance proposals.

### dependencies

#### foundry-rs

Assumes you have ran `foundryup` to install the foundry-rs toolset.

https://book.getfoundry.sh/

https://github.com/foundry-rs/foundry/tree/master/foundryup

#### tor

Assumes you have `tor` installed and running.

https://www.torproject.org/

#### torsocks

Assumes you have `torsocks` installed and on your shell's path.

https://gitlab.torproject.org/tpo/core/torsocks/

### to install and setup environment

1. `git clone https://github.com/ob1ock/tornadocash-governance-cli`
1. `forge install`
1. start `./tor`
1. add `torsocks` to PATH
1. `source tornadocash-governance-cli.sh`

### usage

```shell
tornadocash-governance-cli
Usage:
tornadocash_governance_cli --proposal-details <id>
tornadocash_governance_cli --proposal-latest <?block-number>
tornadocash_governance_cli --proposal <proposal-id> <?block-number>
tornadocash_governance_cli --solidity-file /path/to/file <?block-number>
```

### examples

```shell
$ tornadocash_governance_cli --proposal-details 53
$ tornadocash_governance_cli --proposal-latest
$ tornadocash_governance_cli --proposal 53 19397278
$ tornadocash_governance_cli --solidity-file Proposal.sol
```
