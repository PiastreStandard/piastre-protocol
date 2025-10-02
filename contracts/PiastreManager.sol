// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PiastreManager {
    address public pst;
    address public dao;
    address public minter;

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
}