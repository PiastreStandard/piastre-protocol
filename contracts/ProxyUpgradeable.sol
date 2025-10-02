// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ProxyUpgradeable is Initializable, UUPSUpgradeable {
    address public version;

    function initialize(address _version) external initializer {
        version = _version;
    }

    function _authorizeUpgrade(address) internal override {}
}