// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DummyLogic is Initializable, UUPSUpgradeable {
    uint256 public version;

    function initialize(uint256 _version) public initializer {
        version = _version;
    }

    function reinitialize(uint256 _newVersion) public reinitializer(2) {
        version = _newVersion;
    }

    // Required for UUPS
    function _authorizeUpgrade(address) internal override {
        require(1 == 1, "Not authorized");
    }
}