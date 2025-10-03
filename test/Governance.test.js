const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Governance", function () {
  let governance, dummyLogic, newDummyLogic;
  let deployer, voters;

  beforeEach(async () => {
    [deployer, ...voters] = await ethers.getSigners();

    const Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy();
    await governance.waitForDeployment();
    await governance.initialize(0);

    const DummyLogic = await ethers.getContractFactory("DummyLogic");

    // Deploy V1 and wrap in a proxy
    const logicV1 = await DummyLogic.deploy();
    await logicV1.waitForDeployment();

    const encodedInit = logicV1.interface.encodeFunctionData("initialize", [0]);
    const Proxy = await ethers.getContractFactory("ERC1967Proxy");
    const proxy = await Proxy.deploy(logicV1.target, encodedInit);
    await proxy.waitForDeployment();

    dummyLogic = await ethers.getContractAt("DummyLogic", proxy.target);

    // Deploy V2 (upgrade target)
    const DummyLogicV2 = await ethers.getContractFactory("DummyLogicV2");
    newDummyLogic = await DummyLogicV2.deploy();
    await newDummyLogic.waitForDeployment();

    // Assign voting power
    const N = Math.min(voters.length, 20);
    for (let i = 0; i < N; i++) {
        await governance.setVotingPower(voters[i].address, 1000 * (N - i));
    }
  });

  const getProposalIdFromTx = async (tx) => {
    const receipt = await tx.wait();
    const parsed = receipt.logs
      .map(log => {
        try {
          return governance.interface.parseLog(log);
        } catch {
          return null;
        }
      })
      .find(e => e?.name === "ProposalCreated");
    return parsed?.args.proposalId;
  };

  it("should create a proposal", async () => {
    const tx = await governance.connect(voters[0]).createProposal(dummyLogic.target, newDummyLogic.target, "0x");
    const proposalId = await getProposalIdFromTx(tx);

    expect(proposalId).to.not.be.undefined;

    const proposal = await governance.proposals(proposalId);
    expect(proposal.target).to.equal(dummyLogic.target);
    expect(proposal.newImplementation).to.equal(newDummyLogic.target);
  });

  it("should allow voting and execute if majority reached", async () => {
    const tx = await governance.connect(voters[0]).createProposal(dummyLogic.target, newDummyLogic.target, "0x");
    const proposalId = await getProposalIdFromTx(tx);

    // Top voters vote YES (more than 50% of total)
    for (let i = 0; i < 10; i++) {
      await governance.connect(voters[i]).vote(proposalId, true);
    }

    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    await expect(governance.executeProposal(proposalId)).to.emit(governance, "Executed");
  });

  it("should allow governor override if no quorum", async () => {
    const tx = await governance.connect(voters[0]).createProposal(dummyLogic.target, newDummyLogic.target, "0x");
    const proposalId = await getProposalIdFromTx(tx);

    for (let i = 0; i < 6; i++) {
      await governance.connect(voters[i]).governorVote(proposalId, true);
    }

    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    await expect(governance.executeProposal(proposalId)).to.emit(governance, "Executed");
  });

  it("should reject execution if no quorum or governor majority", async () => {
    const tx = await governance.connect(voters[0]).createProposal(dummyLogic.target, newDummyLogic.target, "0x");
    const proposalId = await getProposalIdFromTx(tx);

    await governance.connect(voters[10]).vote(proposalId, true); // low-vote YES

    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    await expect(governance.executeProposal(proposalId)).to.be.revertedWith("Proposal did not pass");
  });
});