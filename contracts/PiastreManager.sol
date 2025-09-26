// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PiastreManager {
    address public governanceDAO;
    address public pst;
    address public dao;
    address public minter;

    constructor(
        address _governanceDAO,
        address _pstImpl,
        address _daoImpl,
        address _minterImpl
    ) {
        governanceDAO = _governanceDAO;

        pst = address(new ERC1967Proxy(_pstImpl, ""));
        dao = address(new ERC1967Proxy(_daoImpl, ""));
        minter = address(new ERC1967Proxy(_minterImpl, ""));
    }

    modifier onlyDAO() {
        require(msg.sender == governanceDAO, "Not DAO");
        _;
    }

    function upgradePST(address newImpl) external onlyDAO {
        ERC1967Proxy(payable(pst)).upgradeTo(newImpl);
    }

    function upgradeDAO(address newImpl) external onlyDAO {
        ERC1967Proxy(payable(dao)).upgradeTo(newImpl);
    }

    function upgradeMinter(address newImpl) external onlyDAO {
        ERC1967Proxy(payable(minter)).upgradeTo(newImpl);
    }
}