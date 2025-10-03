// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPiastreManager.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract PiastreToken is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    address public manager;
    IERC20 public usdc;
    IERC20 public wbtc;
    IUniswapV2Router public btcRouter;

    modifier onlyDAO() {
        require(msg.sender == dao(), "Not DAO");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault(), "Not Vault");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdc, address _manager) public initializer {
        __ERC20_init("Piastre", "PIA");
        __ERC20Permit_init("Piastre");

        manager = _manager;
        usdc = IERC20(_usdc);
    }

    function dao() public view returns (address) {
        return IPiastreManager(manager).dao();
    }

    function vault() public view returns (address) {
        return IPiastreManager(manager).getDefaultVault();
    }

    function _authorizeUpgrade(address) internal override onlyDAO {}

    // ======================
    // ===== ADMIN ONLY =====
    // ======================

    function setWBTC(address _wbtc) external onlyDAO {
        wbtc = IERC20(_wbtc);
    }

    function setBTCRouter(address _router) external onlyDAO {
        btcRouter = IUniswapV2Router(_router);
    }

    function setUSDC(address _usdc) external onlyDAO {
        usdc = IERC20(_usdc);
    }

    // ======================
    // ====== MINTING =======
    // ======================

    function mint(address to, uint256 amount) external onlyVault {
        _mint(to, amount);
    }

    // ======================
    // ====== BTC BUY =======
    // ======================

    function buyBTC(uint256 usdcAmount, uint256 minOut) external onlyVault nonReentrant {
        require(address(btcRouter) != address(0), "Router not set");
        require(address(wbtc) != address(0), "WBTC not set");

        usdc.transferFrom(msg.sender, address(this), usdcAmount);
        usdc.approve(address(btcRouter), usdcAmount);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(wbtc);

        btcRouter.swapExactTokensForTokens(
            usdcAmount,
            minOut,
            path,
            vault(),
            block.timestamp + 300
        );
    }

    function wbtcBalance() external view returns (uint256) {
        return wbtc.balanceOf(vault());
    }
}