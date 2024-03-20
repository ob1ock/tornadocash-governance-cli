// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/* oblock */

/// @dev Enum from https://github.com/tornadocash/tornado-governance/blob/master/contracts/v1/Governance.sol
/// @notice Possible states that a proposal may be in
enum ProposalState {

    Pending,
    Active,
    Defeated,
    Timelocked,
    AwaitingExecution,
    Executed,
    Expired
}

/// @dev Struct from https://github.com/tornadocash/tornado-governance/blob/master/contracts/v1/Governance.sol
struct Proposal {

    address proposer;
    address target;
    uint256 startTime;
    uint256 endTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool extended;
}

interface IGovernance {
    
    function castVote(uint256 proposalId, bool support) external;
    function execute(uint256 proposalId) external payable;
    function lock(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function propose(address target, string memory description) external returns (uint256);
    function proposals(uint256 index) external view returns (Proposal memory);

    function VOTING_PERIOD() external view returns (uint256);
    function EXECUTION_DELAY() external view returns (uint256);
}

/// @notice Contract to simulate Tornado Cash Governance proposals.
/// @author oblock
contract ProposalTest is Test {

	address constant tornAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
	address constant governanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

	address voter;
	uint256 voter_private_key;

	uint256 proposal_id;
	string proposal_contract_filename;
	address proposal_address;

	uint256 amount = 100_001e18;

	IGovernance governance = IGovernance(governanceAddress);

	bytes32 public constant PERMIT_SIGNATURE =
	keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	uint16 public constant PERMIT_SELECTOR = uint16(0x1901);

	bytes32 public constant EIP712_DOMAIN_HASH = keccak256(
		abi.encode(
			keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
			keccak256(bytes("TornadoCash")),
			keccak256(bytes("1")),
			1,
			tornAddress
		)
	);

	function setUp() public {

		(voter, voter_private_key) = makeAddrAndKey("oblock");

		// deal the voter enough TORN for proposal to reach quorom 

		deal(address(tornAddress), voter, amount);
	}

	/// @dev locks TORN in governance contract for voting power
	function lockGovernanceVotes(uint256 _amount, address _user, uint256 _privateKey) public {

		uint256 nonce = ERC20Permit(tornAddress).nonces(_user);

		uint256 lockTimestamp = block.timestamp + governance.VOTING_PERIOD() + governance.EXECUTION_DELAY();

		bytes32 messageHash = keccak256(
			abi.encodePacked(
				PERMIT_SELECTOR,
				EIP712_DOMAIN_HASH,
				keccak256(abi.encode(PERMIT_SIGNATURE, _user, governanceAddress, _amount, nonce, lockTimestamp))
			)
		);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, messageHash);

		IGovernance(governanceAddress).lock(_user, _amount, lockTimestamp, v, r, s);
	}

	///
	function testTornadoCashGovernanceProposal() public {

		string memory _proposal_id = vm.envString("PROPOSAL_ID");

		bool isProposalIdSet = bytes(_proposal_id).length > 0;

		vm.startPrank(voter);

		lockGovernanceVotes(amount, voter, voter_private_key);

		if(!isProposalIdSet) {

			proposal_contract_filename  = vm.envString("PROPOSAL_CONTRACT_FILENAME");

			proposal_address = deployCode(proposal_contract_filename);

			string memory PROPOSAL_DESCRIPTION = "{title:'test',description:'test'}";

			proposal_id = governance.propose(proposal_address, PROPOSAL_DESCRIPTION);

		} else {

			proposal_id = vm.envUint("PROPOSAL_ID");
		}

		vm.warp(block.timestamp + 1 hours);

		governance.castVote(proposal_id, true);

		Proposal memory proposal = governance.proposals(proposal_id);

		vm.warp(proposal.endTime + governance.EXECUTION_DELAY() + 42 seconds);

		governance.execute(proposal_id);

		vm.stopPrank();
	}
}
