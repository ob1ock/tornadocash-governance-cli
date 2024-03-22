# tornadocash-governance-cli
# Script for corresponding forge test contract to simulate Tornado Cash Governance proposals.

# oblock

#
function fetchProposalDetails {

    local id=$1
    echo "Fetch details for proposal id: $id"

    local decoded_proposal=$(decodeProposalsMethod $id)

    # fields from https://github.com/tornadocash/tornado-governance/blob/master/contracts/v1/Governance.sol
    local fields=("proposer" "target" "startTime" "endTime" "forVotes" "againstVotes" "executed" "extended")

    for f in "${fields[@]}"; do
        echo -n "$f "
    done

    echo
    local i=1
    for value in $decoded_proposal; do
        if [ $i -eq 3 ] || [ $i -eq 5 ] || [ $i -eq 7 ]; then
            echo -n "$value "
        elif [ $i -eq 4 ] || [ $i -eq 6 ] || [ $i -eq 8 ]; then
            echo $value
        else
            echo $value
        fi
        ((i++))
    done
}

#
function fetchLatestProposalId {

  local id=$(torsocks cast call $TORNADO_GOVERNANCE_ADDRESS 'proposalCount()' --rpc-url $RPC_URL)

  cast --to-dec $id
}

#
function decodeProposalsMethod {

  local id=$1

  local output=$(torsocks cast call $TORNADO_GOVERNANCE_ADDRESS 'proposals(uint256)' $id --rpc-url $RPC_URL)

  cast abi-decode --input "proposals(address,address,uint256,uint256,uint256,uint256,bool,bool)" $output
}

#
function cleanUpEnvironment {

  unset RPC_URL
  unset TORNADO_GOVERNANCE_ADDRESS

  unset BLOCK_NUMBER

  unset PROPOSAL_CONTRACT_FILENAME
  unset PROPOSAL_ID
}

#
function printUsage {

  echo "tornadocash-governance-cli"
  echo "Usage:"
  echo "tornadocash_governance_cli --proposal-details <id>"
  echo "tornadocash_governance_cli --proposal-latest <?block-number>"
  echo "tornadocash_governance_cli --proposal <proposal-id> <?block-number>"
  echo "tornadocash_governance_cli --solidity-file /path/to/file <?block-number>"
}

# "main"
function tornadocash_governance_cli {

  export RPC_URL="https://rpc.mevblocker.io"

  export TORNADO_GOVERNANCE_ADDRESS="0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce" # LoopbackProxy

  export BLOCK_NUMBER=$(torsocks cast block-number --rpc-url $RPC_URL)

  if [[ "$#" -eq 0 ]]; then

    printUsage

  else
    case $1 in
    --proposal-details)
      if [[ -n "$2" ]]; then
        
        fetchProposalDetails $2
        
        shift
      else
        echo "Error: --proposal-detail option requires an argument."
      fi
      ;;
      --proposal-latest)
      if [[ -n "$1" ]]; then

        local tmp=$2
        local block=${tmp:-$BLOCK_NUMBER} # Optional

        export PROPOSAL_ID=$(fetchLatestProposalId)

        echo "Fetch latest proposal id: $PROPOSAL_ID"

        fetchProposalDetails $PROPOSAL_ID

        # The following executes the setup and testTornadoCashGovernanceProposal 
        # functions defined in Proposal.t.sol using environment variables to configure.
        torsocks forge test -vvvvv --fork-url $RPC_URL --fork-block-number $block \
          --match-test "testTornadoCashGovernanceProposal"
         
        shift
      else
        echo "Error: --proposal-latest option requires an argument."
      fi
      ;;
      --proposal)
      if [[ -n "$2" ]]; then

        local tmp=$3
        local block=${tmp:-$BLOCK_NUMBER} # Optional

        export PROPOSAL_ID=$2

        echo "Executing already proposed contract."
        echo "Note that this function requires knowledge of the block number prior to the vote ending."
        echo "Additionally the RPC_URL environment variable must point to an archival node."

        torsocks forge test -vvvvv --fork-url $RPC_URL --fork-block-number $block \
          --match-test "testTornadoCashGovernanceProposal"

        shift
      else
        echo "Error: --proposal option requires more arguments. See tool usage."
      fi
      ;;
      --solidity-file)
      if [[ -n "$2" ]]; then

        # todo flatten multiple solidity files prior to simulation
        
        echo "Propose and simulate local Solidity file: $2"

        local tmp=$3
        local block=${tmp:-$BLOCK_NUMBER} # Optional

        export PROPOSAL_CONTRACT_FILENAME=$2
        export PROPOSAL_ID=

        torsocks forge test -vvvvv --fork-url $RPC_URL --fork-block-number $block \
          --match-test "testTornadoCashGovernanceProposal"

        shift
      else
        echo "Error: --solidity-file option requires an argument."
      fi
      ;;
      *)
        echo "Unknown parameter passed: $1"
        ;;
    esac
  fi

  cleanUpEnvironment
}
