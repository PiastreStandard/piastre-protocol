// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUpgradeable {
    function upgradeTo(address newImplementation) external;
}

contract Governance {
    struct Proposal {
        address proposer;
        address target;
        address newImplementation;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtCreation;
        uint256 deadline;
        bool executed;
        address[] governorsAtCreation;
        mapping(address => bool) governorVotes;
        uint256 governorVotesFor;
        uint256 governorVotesAgainst;
        uint256 governorVotesCast;
    }

    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower; // TODO: Replace with PiastreBTC.balanceOf()
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed proposalId, address proposer, address target, address newImpl);
    event Voted(uint256 indexed proposalId, address voter, bool support);
    event GovernorVoted(uint256 indexed proposalId, address governor, bool support);
    event Executed(uint256 indexed proposalId);

    modifier onlyEligible() {
        require(votingPower[msg.sender] > 0, "No voting power");
        _;
    }

    function createProposal(
        address target,
        address newImpl
    ) external onlyEligible returns (uint256) {
        proposalCount++;

        // Snapshot top 10 governors by voting power
        address[] memory topGovernors = getTopGovernors();

        Proposal storage p = proposals[proposalCount];
        p.proposer = msg.sender;
        p.target = target;
        p.newImplementation = newImpl;
        p.deadline = block.timestamp + votingPeriod;
        p.totalVotingPowerAtCreation = getTotalVotingPower();
        p.governorsAtCreation = topGovernors;

        emit ProposalCreated(proposalCount, msg.sender, target, newImpl);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external onlyEligible {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            p.votesFor += votingPower[msg.sender];
        } else {
            p.votesAgainst += votingPower[msg.sender];
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function governorVote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.deadline, "Voting ended");
        require(isGovernor(proposalId, msg.sender), "Not a governor");
        require(!p.governorVotes[msg.sender], "Already voted");

        p.governorVotes[msg.sender] = true;
        p.governorVotesCast++;
        if (support) {
            p.governorVotesFor++;
        } else {
            p.governorVotesAgainst++;
        }

        emit GovernorVoted(proposalId, msg.sender, support);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.deadline, "Voting not ended");
        require(!p.executed, "Already executed");

        bool passed;

        // Normal proposals: either community passes OR governors override
        uint256 totalVotes = p.votesFor + p.votesAgainst;
        if (totalVotes * 100 / p.totalVotingPowerAtCreation >= 50) {
            passed = p.votesFor > p.votesAgainst;
        } else if (p.governorVotesCast >= 6 && (p.governorVotesFor * 100 / p.governorVotesCast) > 50) {
            passed = true;
        }

        require(passed, "Proposal did not pass");
        IUpgradeable(p.target).upgradeTo(p.newImplementation);
        p.executed = true;

        emit Executed(proposalId);
    }

    // ---- Governance Utilities (mocked for now) ----

    function getTopGovernors() internal pure returns (address[] memory) {
        // TODO: Replace with logic to pull top 10 PiastreBTC holders
        address[] memory top = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            top[i] = address(uint160(i + 1));
        }
        return top;
    }

    function isGovernor(uint256 proposalId, address user) internal view returns (bool) {
        address[] storage top = proposals[proposalId].governorsAtCreation;
        for (uint256 i = 0; i < top.length; i++) {
            if (top[i] == user) return true;
        }
        return false;
    }

    function getTotalVotingPower() internal pure returns (uint256) {
        // TODO: Replace with real supply snapshot
        return 1000000;
    }

    // TEMPORARY: assign mock voting power manually
    function setVotingPower(address user, uint256 amount) external {
        votingPower[user] = amount;
    }
}
