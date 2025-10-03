// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPiastreManager.sol";

contract BTCVault {
    using Address for address;

    address public immutable manager;
    mapping(address => bool) public approvedBTC;
    uint256 public sellThreshold; // in USDC (or USD-equivalent)

    event BTCWithdrawn(address indexed token, address indexed to, uint256 amount);
    event BTCApproved(address indexed token, bool approved);
    event ThresholdUpdated(uint256 newThreshold);
    event VaultDeployed(address indexed vault, address indexed manager);

    modifier onlyDAO() {
        require(msg.sender == IPiastreManager(manager).dao(), "Not DAO");
        _;
    }

    constructor(address _manager, uint256 _initialThreshold) {
        require(_manager != address(0), "Invalid manager");
        manager = _manager;
        sellThreshold = _initialThreshold;
        emit VaultDeployed(address(this), _manager);
    }

    function withdrawBTC(address token, address to, uint256 amount) external onlyDAO {
        require(approvedBTC[token], "Token not approved");
        require(to != address(0), "Invalid recipient");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "Insufficient balance");

        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");

        emit BTCWithdrawn(token, to, amount);
    }

    function setThreshold(uint256 newThreshold) external onlyDAO {
        sellThreshold = newThreshold;
        emit ThresholdUpdated(newThreshold);
    }

    function approveBTC(address token, bool approved) external onlyDAO {
        approvedBTC[token] = approved;
        emit BTCApproved(token, approved);
    }

    function getManagerDAO() external view returns (address) {
        return IPiastreManager(manager).dao();
    }

    // Disable fallback and receive
    fallback() external payable {
        revert("Fallback disabled");
    }

    receive() external payable {
        revert("Direct ETH not allowed");
    }
}