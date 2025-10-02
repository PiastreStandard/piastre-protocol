const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PiastreManager", function () {
  let manager;
  let governanceDAO;
  let pstImpl;
  let daoImpl;
  let minterImpl;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    governanceDAO = deployer.address;

    const Governance = await ethers.getContractFactory("Governance");
    daoImpl = await Governance.deploy();
    await daoImpl.waitForDeployment();

    const DummyLogic = await ethers.getContractFactory("DummyLogic");
    pstImpl = await DummyLogic.deploy();
    await pstImpl.waitForDeployment();

    minterImpl = await DummyLogic.deploy();
    await minterImpl.waitForDeployment();

    const Manager = await ethers.getContractFactory("PiastreManager");
    manager = await Manager.deploy(
      pstImpl.target,
      daoImpl.target,
      minterImpl.target
    );
  });

  it("should deploy successfully", async function () {
    expect(manager.target).to.properAddress;
  });
});