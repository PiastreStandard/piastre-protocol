# Piastre Protocol – Smart Contracts

This repository contains the full suite of EVM-compatible smart contracts powering the **Piastre DAO**: a fully decentralized, dual-token investment protocol with auto-dividends, governance, and Bitcoin-backed stablecoin mechanics.

---

## 🧱 Overview

Piastre is a decentralized, trustless investment system consisting of:

### 🪙 PiastreToken (PST)
- 1:1 backed mintable stablecoin (minted via USDC)
- 15% of mint value sent to dividend pool
- 85% auto-swapped to wBTC and held by contract
- 1% tax on transfers (governance-controlled)
- Triggers Piastre BTC mining

### 🪙 Piastre BTC (Governance Token)
- ERC20 governance token
- Issued on halving curve based on PST minted
- Controls protocol parameters (tax, sell %, treasury)

### 🏦 DividendPool
- Holds USDC for daily dividends
- Users claim via Merkle proofs

### 🗳 DAO / Governance Contract
- Proposal creation, voting, and execution
- Full on-chain governance system

### 🔁 PiastreBTCMinter
- Tracks PST issuance milestones
- Enforces halving-based reward curve

### 💰 TaxPool
- Collects 1% PST transfer tax
- Distributes tax rewards to Piastre BTC holders

---

## 🔐 Key Features

- 🛠 **Fully on-chain** – No backend required
- ⚖ **Trustless Bitcoin-backed reserve (wBTC)**
- 🧮 **Auto-distributed dividends via Merkle tree**
- 🗳 **Fully custom on-chain governance**
- 💳 **Credit card buy flow via PayPangea (frontend)**

---

## 📂 Contracts Included

| Contract              | Purpose                                 |
|-----------------------|------------------------------------------|
| `PiastreToken.sol`    | Stable token (mint, transfer, tax)       |
| `PiastreBTC.sol`      | Governance token                         |
| `DividendPool.sol`    | Merkle-based dividend claims             |
| `Governance.sol`      | DAO proposal + voting system             |
| `PiastreBTCMinter.sol`| Halving logic for Piastre BTC            |
| `TaxPool.sol`         | Tax collection and distribution          |

---

## 🛠 Development

### Prerequisites
- Node.js v18+
- Foundry or Hardhat
- Ethers.js

### Install

```bash
git clone https://github.com/PiastreStandard/piastre-core.git
cd piastre-core
npm install
