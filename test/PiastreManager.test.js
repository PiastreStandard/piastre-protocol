const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PiastreManager with DAO Governance", function () {
  let manager;
  let pstImpl;
  let daoImpl;
  let minterImpl;
  let vault1, vault2;
  let deployer, voters;
  let governance;

  async function executeAsDAO(target, callData) {
    const tx = await governance.connect(voters[0]).createProposal(target, ethers.ZeroAddress, callData);
    const receipt = await tx.wait();
    const event = receipt.logs.find(log => log.fragment.name === "ProposalCreated");
    const proposalId = event.args.proposalId;

    for (let i = 0; i < 10; i++) {
      await governance.connect(voters[i]).vote(proposalId, true);
    }

    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    await governance.executeProposal(proposalId);
  }

  beforeEach(async function () {
    [deployer, vault1, vault2, ...voters] = await ethers.getSigners();

    const DummyLogic = await ethers.getContractFactory("DummyLogic");
    pstImpl = await DummyLogic.deploy();
    await pstImpl.waitForDeployment();

    daoImpl = await (await ethers.getContractFactory("Governance")).deploy();
    await daoImpl.waitForDeployment();

    minterImpl = await DummyLogic.deploy();
    await minterImpl.waitForDeployment();

    const Manager = await ethers.getContractFactory("PiastreManager");
    manager = await Manager.deploy(
      pstImpl.target,
      daoImpl.target,
      minterImpl.target
    );

    const daoAddress = await manager.dao();
    governance = await ethers.getContractAt("Governance", daoAddress);

    await governance.initialize(0);
    // Assign voting power
    const N = Math.min(voters.length, 20);
    for (let i = 0; i < N; i++) {
      await governance.setVotingPower(voters[i].address, 1000 * (N - i));
    }
  });

  it("should deploy successfully", async function () {
    expect(manager.target).to.properAddress;
  });

  it("should add and retrieve vaults", async function () {
    const iface = new ethers.Interface(["function addVault(address)"]);
    const data = iface.encodeFunctionData("addVault", [vault1.address]);
    await executeAsDAO(manager.target, data);

    expect(await manager.vaultCount()).to.equal(1);
    expect((await manager.getVaults())[0]).to.equal(vault1.address);
  });

  it("should not allow duplicate vaults", async function () {
    const iface = new ethers.Interface(["function addVault(address)"]);
    const data = iface.encodeFunctionData("addVault", [vault1.address]);

    await executeAsDAO(manager.target, data);
    await expect(executeAsDAO(manager.target, data)).to.be.revertedWith("Vault already added");
  });

  it("should set and return default vault", async function () {
    const i1 = new ethers.Interface(["function addVault(address)"]);
    const i2 = new ethers.Interface(["function setDefaultVault(address)"]);

    await executeAsDAO(manager.target, i1.encodeFunctionData("addVault", [vault1.address]));
    await executeAsDAO(manager.target, i2.encodeFunctionData("setDefaultVault", [vault1.address]));

    expect(await manager.getVault()).to.equal(vault1.address);
  });

  it("should reject setting default vault if not registered", async function () {
    const iface = new ethers.Interface(["function setDefaultVault(address)"]);
    const data = iface.encodeFunctionData("setDefaultVault", [vault2.address]);
    await expect(executeAsDAO(manager.target, data)).to.be.revertedWith("Vault not registered");
  });
});