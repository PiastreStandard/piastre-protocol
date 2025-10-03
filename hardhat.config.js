require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.22",
  paths: {
    sources: "./contracts",
    tests: "./test",
    scripts: "./scripts",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
