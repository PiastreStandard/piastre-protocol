const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PiastreManager + Governance upgradeDAO test", function () {
  let deployer, voters;
  let manager;
  let daoLogicV1, daoLogicV2, daoProxy;
  let DAOProxy;

  const advanceTime = async (days) => {
    await ethers.provider.send("evm_increaseTime", [days * 86400]);
    await ethers.provider.send("evm_mine");
  };

  const getProposalIdFromTx = async (tx) => {
    const receipt = await tx.wait();
    const parsed = receipt.logs
      .map(log => {
        try {
          return DAOProxy.interface.parseLog(log);
        } catch {
          return null;
        }
      })
      .find(e => e?.name === "ProposalCreated");
    return parsed?.args.proposalId;
  };


  beforeEach(async () => {
    [deployer, ...voters] = await ethers.getSigners();

    const Governance = await ethers.getContractFactory("Governance");
    const DummyLogic = await ethers.getContractFactory("DummyLogic");
    const Proxy = await ethers.getContractFactory("ERC1967Proxy");

    daoLogicV1 = await Governance.deploy();
    await daoLogicV1.waitForDeployment();

    daoProxy = await Proxy.deploy(daoLogicV1.target, "0x");
    await daoProxy.waitForDeployment();

    // ✅ Get Governance ABI at proxy address
    DAOProxy = await ethers.getContractAt("Governance", daoProxy.target);

    // ✅ Init the proxy
    await DAOProxy.initialize(0);

    const dummyImpl = await DummyLogic.deploy();
    await dummyImpl.waitForDeployment();
    const pstProxy = await Proxy.deploy(dummyImpl.target, "0x");
    const minterProxy = await Proxy.deploy(dummyImpl.target, "0x");

    await pstProxy.waitForDeployment();
    await minterProxy.waitForDeployment();

    const PiastreManager = await ethers.getContractFactory("PiastreManager");
    manager = await PiastreManager.deploy(
      pstProxy.target,
      daoProxy.target,
      minterProxy.target
    );
    await manager.waitForDeployment();

    daoLogicV2 = await Governance.deploy();
    await daoLogicV2.waitForDeployment();
    // await daoLogicV2.initialize(1);

    // ✅ Set voting power via Governance proxy (DAOProxy)
    for (let i = 0; i < 5; i++) {
      await DAOProxy.setVotingPower(voters[i].address, 1000);
    }
  });

  it("should upgrade DAO proxy via governance vote", async () => {
    expect(await DAOProxy.version()).to.equal(0); // use the proxy instance

    const tx = await DAOProxy.connect(voters[0]).createProposal(
      daoProxy.target,
      daoLogicV2.target
    );
    const proposalId = await getProposalIdFromTx(tx);

    const [,,,,,, deadline] = await DAOProxy.getProposal(proposalId);
    const block = await ethers.provider.getBlock('latest');
    
    for (let i = 0; i < 3; i++) {

    const now = (await ethers.provider.getBlock('latest')).timestamp;
      await DAOProxy.connect(voters[i]).vote(proposalId, true);
    }

    await advanceTime(3);

    await expect(DAOProxy.executeProposal(proposalId)).to.emit(DAOProxy, "Executed");

    const upgraded = await ethers.getContractAt("Governance", daoProxy.target);
    expect(await upgraded.version()).to.equal(1);
  });
});