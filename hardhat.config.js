require("@nomicfoundation/hardhat-toolbox");

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
