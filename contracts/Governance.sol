// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IUpgradeable {
    function upgradeToAndCall(address newImpl, bytes calldata data) external;
}

contract Governance is Initializable, UUPSUpgradeable {
    struct Proposal {
        address proposer;
        address target;
        address newImplementation; // optional
        bytes callData;            // <== NEW
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
    uint256 public votingPeriod;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // New: track voters for top-governor snapshot
    uint256 public voterCount;
    mapping(uint256 => address) public voterList;

    event ProposalCreated(uint256 indexed proposalId, address proposer, address target, address newImpl);
    event Voted(uint256 indexed proposalId, address voter, bool support);
    event GovernorVoted(uint256 indexed proposalId, address governor, bool support);
    event Executed(uint256 indexed proposalId);

    uint256 public version;

    function initialize(uint256 _version) public initializer {
        __UUPSUpgradeable_init();
        version = _version;
        votingPeriod = 3 days;
    }


    function reinitialize(uint256 _newVersion) public reinitializer(2) {
        version = _newVersion;
        votingPeriod = 3 days;
    }

    function _authorizeUpgrade(address) internal override {
        // allow either the proxy itself or the governance contract to trigger upgrade

        require(
            msg.sender == address(this),
            "Only Governance can upgrade"
        );
    }

    modifier onlyEligible() {
        require(votingPower[msg.sender] > 0, "No voting power");
        _;
    }

    function createProposal(
        address target,
        address newImpl,
        bytes calldata callData
    ) external onlyEligible returns (uint256) {
        uint256 proposalId = proposalCount++;

        address[] memory topGovernors = getTopGovernors();

        Proposal storage p = proposals[proposalId];
        p.proposer = msg.sender;
        p.target = target;
        p.newImplementation = newImpl;
        p.callData = callData; // <== store calldata
        p.deadline = block.timestamp + votingPeriod;
        p.totalVotingPowerAtCreation = getTotalVotingPower();
        p.governorsAtCreation = topGovernors;

        emit ProposalCreated(proposalId, msg.sender, target, newImpl);
        return proposalId;
    }

    function getProposal(uint256 id) external view returns (
        address proposer,
        address target,
        address newImplementation,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 totalVotingPowerAtCreation,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage p = proposals[id];
        return (
            p.proposer,
            p.target,
            p.newImplementation,
            p.votesFor,
            p.votesAgainst,
            p.totalVotingPowerAtCreation,
            p.deadline,
            p.executed
        );
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
        uint256 totalVotes = p.votesFor + p.votesAgainst;

        if (totalVotes * 100 / p.totalVotingPowerAtCreation >= 50) {
            passed = p.votesFor > p.votesAgainst;
        } else if (p.governorVotesCast >= 6 && (p.governorVotesFor * 100 / p.governorVotesCast) > 50) {
            passed = true;
        }

        require(passed, "Proposal did not pass");
        
        if (p.callData.length == 0) {
            // Normal upgrade flow
            IUpgradeable(p.target).upgradeToAndCall(
                p.newImplementation,
                abi.encodeWithSignature("reinitialize(uint256)", version + 1)
            );
        } else {
            // General DAO call
            (bool success, bytes memory result) = p.target.call(p.callData);
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }

        p.executed = true;
        emit Executed(proposalId);
    }

    function getTopGovernors() internal view returns (address[] memory) {
        address[] memory sorted = new address[](voterCount);
        for (uint256 i = 0; i < voterCount; i++) {
            sorted[i] = voterList[i];
        }

        for (uint256 i = 0; i < voterCount; i++) {
            for (uint256 j = i + 1; j < voterCount; j++) {
                if (votingPower[sorted[j]] > votingPower[sorted[i]]) {
                    address temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }

        uint256 topLen = voterCount < 10 ? voterCount : 10;
        address[] memory top = new address[](topLen);
        for (uint256 i = 0; i < topLen; i++) {
            top[i] = sorted[i];
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

    function getTotalVotingPower() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < voterCount; i++) {
            total += votingPower[voterList[i]];
        }
        return total;
    }

    function setVotingPower(address user, uint256 amount) external {
        if (votingPower[user] == 0 && amount > 0) {
            voterList[voterCount] = user;
            voterCount++;
        }
        votingPower[user] = amount;
    }
}