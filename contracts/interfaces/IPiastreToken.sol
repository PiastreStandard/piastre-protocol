// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPiastreToken {
    function mint(address to, uint256 amount) external;
    function buyBTC(uint256 usdcAmount, uint256 minOut) external;
}