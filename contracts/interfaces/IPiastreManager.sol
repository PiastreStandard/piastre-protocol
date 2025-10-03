// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPiastreManager {
    function dao() external view returns (address);
    function getDefaultVault() external view returns (address);
}