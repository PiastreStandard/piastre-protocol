// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPiastreManager.sol";
import "./interfaces/IPiastreToken.sol";

contract PiastreMinter is ReentrancyGuard {
    address public manager;
    IERC20 public usdc;
    IPiastreToken public piastre;

    event Minted(address indexed user, uint256 usdcAmount, uint256 mintedAmount);

    modifier onlyDAO() {
        require(msg.sender == dao(), "Not DAO");
        _;
    }

    constructor(address _manager, address _usdc, address _piastre) {
        manager = _manager;
        usdc = IERC20(_usdc);
        piastre = IPiastreToken(_piastre);
    }

    function dao() public view returns (address) {
        return IPiastreManager(manager).dao();
    }

    function vault() public view returns (address) {
        return IPiastreManager(manager).getDefaultVault();
    }

    function setUSDC(address _usdc) external onlyDAO {
        usdc = IERC20(_usdc);
    }

    function setPiastreToken(address _token) external onlyDAO {
        piastre = IPiastreToken(_token);
    }

    /// @notice Buy Piastre with USDC; 1:1 exchange
    function mint(uint256 amount, uint256 minBtcOut) external nonReentrant {
        require(amount > 0, "Zero amount");

        // Transfer USDC from user
        require(usdc.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        // Approve PiastreToken to use USDC
        require(usdc.approve(address(piastre), amount), "USDC approve failed");

        // Call buyBTC and route to vault
        piastre.buyBTC(amount, minBtcOut);

        // Mint Piastre 1:1 to sender
        piastre.mint(msg.sender, amount);

        emit Minted(msg.sender, amount, amount);
    }
}