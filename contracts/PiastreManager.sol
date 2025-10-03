// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PiastreManager {
    address public pst;
    address public dao;
    address public minter;

    address[] public vaults;
    mapping(address => bool) public isVault;
    address public defaultVault;

    event VaultAdded(address indexed vault);
    event DefaultVaultChanged(address indexed vault);

    constructor(
        address _pstImpl,
        address _daoImpl,
        address _minterImpl
    ) {
        pst = address(new ERC1967Proxy(_pstImpl, ""));
        dao = address(new ERC1967Proxy(_daoImpl, ""));
        minter = address(new ERC1967Proxy(_minterImpl, ""));
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    // === Proxy Upgrades ===
    function upgradePST(address newImpl) external onlyDAO {
        (bool success, ) = pst.call(
            abi.encodeWithSignature("upgradeTo(address)", newImpl)
        );
        require(success, "PST upgrade failed");
    }

    function upgradeDAO(address newImpl) external onlyDAO {
        (bool success, ) = dao.call(
            abi.encodeWithSignature("upgradeTo(address)", newImpl)
        );
        require(success, "DAO upgrade failed");
    }

    function upgradeMinter(address newImpl) external onlyDAO {
        (bool success, ) = minter.call(
            abi.encodeWithSignature("upgradeTo(address)", newImpl)
        );
        require(success, "Minter upgrade failed");
    }

    // === Vault Registry ===
    function addVault(address vault) external onlyDAO {
        require(vault != address(0), "Invalid vault");
        require(!isVault[vault], "Vault already added");

        isVault[vault] = true;
        vaults.push(vault);

        emit VaultAdded(vault);
    }

    function setDefaultVault(address vault) external onlyDAO {
        require(isVault[vault], "Vault not registered");
        defaultVault = vault;
        emit DefaultVaultChanged(vault);
    }

    function getVault() external view returns (address) {
        require(defaultVault != address(0), "No default vault set");
        return defaultVault;
    }

    function getVaults() external view returns (address[] memory) {
        return vaults;
    }

    function vaultCount() external view returns (uint256) {
        return vaults.length;
    }
}