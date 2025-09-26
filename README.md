# Piastre DAO Smart Contracts

This repository contains the smart contract scaffolding for the Piastre DAO protocol, a dual-token system combining a stable USDC-minted token and a governance asset backed by wBTC.

## 📄 Description

- `PiastreToken.sol` — USDC-pegged utility token
- `PiastreBTC.sol` — governance token with halving issuance
- `DividendPool.sol` — daily dividend distribution (Merkle-based)
- `Governance.sol` — custom proposal and voting system
- `PiastreBTCMinter.sol` — tracks mint history and calculates halving-based PiastreBTC emissions
- `TaxPool.sol` — accumulates 1% tax and rewards governance token holders

## 📦 Getting Started

1. Install dependencies:
```bash
npm install
```

2. Compile contracts:
```bash
npx hardhat compile
```

3. Run tests:
```bash
npx hardhat test
```

## 🧪 Tooling

- Hardhat for compilation and testing
- Ethers.js for interactions
- OpenZeppelin for standard contracts

## 📜 License

This project is licensed under the MIT License. See `LICENSE` for more.

## 👥 Authors

Developed by the PiastreStandard team.
