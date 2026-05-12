# Brain EXE

> A sentient digital organism compiled on Ethereum. Post-quantum ready. Deflationary by design.

Brain EXE is an on-chain ERC-20 protocol with fair-launch tokenomics, post-quantum cryptographic infrastructure, and an interactive 3D minting interface. No bonding curves, no bot advantages, no admin keys after deployment.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Smart Contracts](#smart-contracts)
  - [Token Specification](#token-specification)
  - [Mint Mechanism](#mint-mechanism)
  - [Tax Mechanics](#tax-mechanics)
  - [Allocation](#allocation)
  - [Trust Model](#trust-model)
  - [Contract Details](#contract-details)
  - [Key Functions](#key-functions)
- [Post-Quantum Mint Gate](#post-quantum-mint-gate)
- [Core Innovation](#core-innovation)
- [Roadmap](#roadmap)
- [Deploy](#deploy)
- [Verify on Etherscan](#verify-on-etherscan)
- [Run Frontend](#run-frontend)
- [Tech Stack](#tech-stack)
- [Disclaimer](#disclaimer)

---

## Overview

Brain EXE ($EXE) is a hash-based, post-quantum aware, fair-launch token with immutable mechanics and fully auditable minting. The protocol is designed to be finished at 100% mint — no team unlock, no admin keys, no upgrades.

| Parameter | Value |
|-----------|-------|
| Token Name | Brain EXE |
| Symbol | $EXE |
| Decimals | 18 |
| Max Supply | 1,000,000,000 $EXE |
| Public Mint | 650,000,000 $EXE (65%) |
| Liquidity Pool | 350,000,000 $EXE (35%) |
| Mint Rate | 0.001 ETH = 50,000 $EXE |
| Max Mint per Wallet | 500,000 $EXE (0.01 ETH) |
| Transfer Burn Fee | 0.5% |
| Fee Recipient | Burned (deflationary) |
| Chain | Ethereum (Sepolia testnet) |
| Token Standard | ERC-20 + Ownable + Pausable + ReentrancyGuard |

---

## Features

- **Fair Launch Minting**: Fixed-rate, first-come-first-served public sale. No bonding curve, no price discovery games, no bot advantage.
- **Deflationary by Design**: 0.5% of every transfer is permanently burned to `address(0)`. Supply shrinks with every trade.
- **Post-Quantum Security**: SLH-DSA (SPHINCS+) hash-based signature integration for high-value custody and mint attestation.
- **Merkle-Auditable Mints**: Every mint batch produces a Merkle root published every 5 minutes via backend cron. Anyone can reconstruct the full mint tree offline.
- **Immutable Contract**: No proxy pattern, no upgradeability. Ownership renounced at deployment.
- **Burned Team Allocation**: 5% team reserve pre-minted at T-0 and immediately burned to `0x...dEaD`. Forever unspendable.
- **3D Interactive Frontend**: Floating "EXE" 3D text, particle systems, and wireframe grid rendered with React Three Fiber.
- **Account Abstraction**: BrainAccount smart contract wallet with EIP-1271 signature validation, batch execution, and social recovery.

---

## Project Structure

```
Brain EXE/
├── contracts/
│   ├── BrainAccount.sol       # Smart contract wallet (EIP-1271, batch exec, social recovery)
│   ├── BrainEXE.sol           # Main ERC-20 token contract
│   ├── IMintGate.sol          # Mint gate interface
│   └── MintGate.sol           # Mint gate implementation with PQ verification
├── scripts/
│   ├── deploy.js              # Hardhat deployment script
│   └── update-contract.js     # Contract update script
├── frontend/
│   ├── src/
│   │   ├── App.jsx            # Main React app component
│   │   ├── main.jsx           # React entry point
│   │   ├── index.css          # Global styles & glitch effects
│   │   ├── components/
│   │   │   ├── CoreInnovation.jsx   # PQ crypto showcase
│   │   │   ├── Whitepaper.jsx       # Protocol specification
│   │   │   ├── Manifesto.jsx        # Story & manifesto
│   │   │   ├── Scene3D.jsx          # 3D background scene (React Three Fiber)
│   │   │   └── VFXText.jsx          # VFX text components
│   │   └── lib/
│   │       ├── crypto-pq.js         # Post-quantum crypto (SLH-DSA / SPHINCS+)
│   │       ├── crypto.js            # AES key encryption/decryption
│   │       ├── merkle-helper.js     # Merkle tree utilities
│   │       └── supabase.js          # Supabase client
│   ├── public/
│   │   ├── logo.png                 # Brand logo
│   │   └── fonts/
│   │       └── fredoka-bold.ttf     # 3D text font
│   ├── index.html
│   ├── package.json
│   └── vite.config.js
├── hardhat.config.js
├── package.json
└── README.md
```

---

## Prerequisites

- [Node.js](https://nodejs.org/) v18+
- MetaMask or any EVM-compatible wallet
- RPC endpoint (optional, for testnet/mainnet deployment)
- Etherscan API Key (optional, for verification)

---

## Installation

```bash
# 1. Install root dependencies (Hardhat, contracts)
npm install

# 2. Install frontend dependencies (React, Three.js, Thirdweb)
cd frontend && npm install

# 3. Create environment file (optional, for deployment)
cp .env.example .env
# Edit .env and fill in PRIVATE_KEY, RPC URLs, and ETHERSCAN_API_KEY
```

---

## Smart Contracts

### Token Specification

| Property | Value |
|----------|-------|
| Token Standard | ERC-20 |
| Max Supply | 1,000,000,000 EXE |
| Mintable Supply | 650,000,000 EXE (65%) |
| Decimals | 18 |
| Chain | Ethereum (Sepolia testnet) |
| Rate | 0.001 ETH = 50,000 EXE |
| Max / Wallet | 500,000 EXE |
| Transfer Burn Fee | 0.5% |
| Burn Address | `0x0000...0000` |
| Fee Recipient | Burned (deflationary) |

### Mint Mechanism

The public mint is a bonded, first-come-first-served sale. Users send ETH to the Mint Contract and receive EXE tokens instantly at a fixed rate.

1. **Fixed Rate** — 0.001 ETH = 50,000 EXE. The rate is hardcoded and immutable.
2. **Per-Wallet Cap** — Max 500,000 EXE per wallet. Prevents whale concentration and encourages broad distribution.
3. **Merkle Logging** — Every mint is hashed into a Merkle tree. Roots published every 5 minutes via backend cron.
4. **Supply Hard Cap** — 650,000,000 EXE mintable. Once reached, minting stops forever. No inflation.

### Tax Mechanics

| Type | Rate | Description |
|------|------|-------------|
| Mint Tax | 0% | Minting has zero tax. Full allocation to minter. |
| Transfer Burn | 0.5% | Every transfer burns 0.5%. Deflationary forever. |
| Supply | ↓ | Burns reduce total supply permanently. No cap refill. |

### Allocation

| Allocation | Percentage | Description |
|------------|------------|-------------|
| Public Mint | ~65% | Fair launch. Minted progressively by the community. |
| Liquidity Pool | ~30% | Auto-adjusts as minting progresses. Paired with raised ETH on Uniswap at 100% mint. |
| Team | 5% | Pre-minted at T-0 and immediately burned to `0x...dEaD`. Forever 0. |

> **Note**: Team allocation (5%) is burned to `0x000000000000000000000000000000000000dEaD` at T-0. This is irreversible and verifiable on-chain.

### Trust Model

| Feature | Description |
|---------|-------------|
| **No Admin Keys** | Ownership renounced at deployment. No pause, no blacklist, no upgrade proxy. The contract is immutable. |
| **Burned Team Allocation** | 5% team reserve minted to deployer and sent to `0x...dEaD` within the same block. Verifiable on-chain. Forever unspendable. |
| **Merkle Auditable Mints** | Every mint batch produces a Merkle root published every 5 minutes. Anyone can reconstruct the full mint tree offline. |
| **Quantum-Ready Custody** | SLH-DSA (hash-based post-quantum) wallet module for high-value custody. Reduces to keccak256 security only. |
| **Deflationary Burn** | 0.5% of every transfer is burned to `address(0)`. Supply shrinks with every trade. No team treasury, no admin drain. |
| **No Vesting, No Unlock** | Protocol is finished at 100% mint. LP deployed. No future token emissions. No team cliff. Nothing left to unlock. |

### Contract Details

| Property | Value |
|----------|-------|
| Network | Ethereum Sepolia (Testnet) |
| Solidity Version | 0.8.28 |
| EVM Target | Paris |
| Optimizer | Enabled (200 runs) |
| Token Standard | ERC-20 + Ownable + Pausable + ReentrancyGuard |
| Proxy Pattern | None (direct deployment) |
| Upgradeable | No |
| License | MIT |

Contract source code is verified on Etherscan. Anyone can inspect the implementation, verify the bytecode, and audit the logic independently.

### Key Functions

| Function | Description |
|----------|-------------|
| `mint() payable` | Mint EXE by sending ETH. Fixed rate, capped supply. |
| `transferBurnFee() view` | Returns current burn fee in basis points (default 50 = 0.5%). |
| `burnFeeEnabled() view` | Returns true if burn tax is active. |
| `totalMinted() view` | Total EXE minted by public so far. |
| `mintedByWallet(address) view` | Amount minted by a specific wallet. |
| `toggleMint(bool)` | Owner only. Enable or disable minting. |
| `setTransferBurnFee(uint256)` | Owner only. Update burn fee (max 5%). |
| `toggleBurnFee(bool)` | Owner only. Enable or disable burn tax. |
| `withdraw()` | Owner only. Withdraw raised ETH from contract. |
| `pause() / unpause()` | Owner only. Emergency pause/unpause all transfers. |
| `BrainAccount.execute()` | Smart contract wallet — arbitrary call execution with programmable ownership. |
| `BrainAccount.executeBatch()` | Batch multiple calls in one tx. Save gas, atomic execution. |
| `BrainAccount.isValidSignature()` | EIP-1271 signature validation. Smart contracts can sign too. |
| `BrainAccount.confirmOwnershipChange()` | Social recovery — confirm new owner after 2-day delay. |

---

## Post-Quantum Mint Gate

A post-quantum mint gate built on **SLH-DSA (SPHINCS+)** hash-based signatures. Users generate a PQ keypair client-side, sign a challenge message, and submit for off-chain verification. Once verified, the user receives a Merkle Proof or ECDSA attestation that unlocks on-chain minting.

- **Algorithm**: SLH-DSA (SPHINCS+)
- **Signature Size**: ~8 KB
- **On-Chain Verification**: Merkle + ECDSA
- **Security**: No elliptic curves in the PQ layer. Security reduces purely to keccak256 collision-resistance.

### How It Works

1. **Client-Side Key Generation** — SPHINCS+ keypairs are generated entirely in the browser using `@noble/post-quantum`. Private seeds are never transmitted.
2. **Off-Chain PQ Verification** — Signatures are verified off-chain (frontend/backend) using SLH-DSA. No expensive PQ operations on-chain.
3. **Merkle Proof or ECDSA Attestation** — After PQ verification, the backend issues a Merkle Proof or ECDSA attestation. On-chain only verifies these lightweight proofs.
4. **Mint Gate Enforcement** — Only wallets with valid PQ attestation can mint $EXE. The mint function checks the Merkle root or ECDSA attestation before executing.

---

## Core Innovation

- **SLH-DSA / SPHINCS+ Integration**: Hash-based post-quantum signatures for wallet custody and mint attestation.
- **Merkle Tree Logging**: Every mint batch is timestamped and independently auditable via published Merkle roots.
- **AES-256 Key Encryption**: Private keys encrypted at rest using AES-GCM with user-derived passwords.
- **Smart Contract Wallet (BrainAccount)**: EIP-1271 compliant wallet with batch execution, programmable ownership, and social recovery with 2-day timelock.
- **Deflationary Mechanics**: Permanent burn on every transfer. No treasury, no admin drain.

---

## Roadmap

| Phase | Title | Status | Description |
|-------|-------|--------|-------------|
| T-0 | Genesis | ✅ Completed | Deploy Contract Mint and Contract Token. LP and team reserves pre-minted. Team reserve subsequently burned to `0x...dEaD`. |
| First Mint | Merkle Root Publishing | ✅ Completed | Backend cron starts publishing Merkle roots every 5 minutes. Every mint batch is timestamped and independently auditable. |
| 50% Mint | Audit Bundle | 🔄 In Progress | Full audit bundle published; community can independently verify every mint, every root, and every state transition off-chain. |
| 100% Mint | Liquidity Deployment | ⏳ Pending | LP reserve paired with raised ETH on Uniswap. Protocol is finished forever — no team unlock, no admin keys, no upgrades. |

---

## Deploy

### Compile Contracts

```bash
npm run compile
```

### Local (Hardhat Network)

```bash
# Terminal 1: start local node
npx hardhat node

# Terminal 2: deploy
npm run deploy:local
```

### Sepolia Testnet

```bash
npm run deploy:sepolia
```

### Mainnet

```bash
npm run deploy:mainnet
```

> **Important**: Update `CONTRACT_ADDRESS` in `frontend/src/App.jsx` with the deployed contract address.

After deployment, call `setPair()` with the DEX pair address to activate transfer taxes.

---

## Verify on Etherscan

```bash
npx hardhat verify --network <network> <DEPLOYED_ADDRESS> <TREASURY_ADDRESS>
```

---

## Run Frontend

### Development

```bash
cd frontend
npm run dev
```

Then open `http://localhost:5173` and connect your wallet.

### Production Build

```bash
cd frontend
npm run build
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Smart Contracts | Solidity ^0.8.28 |
| Frontend Framework | React 18 + Vite |
| Web3 SDK | Thirdweb |
| 3D Graphics | @react-three/fiber, @react-three/drei, Three.js |
| VFX | react-vfx (WebGL shaders) |
| Styling | Tailwind CSS |
| Post-Quantum Crypto | SLH-DSA / SPHINCS+ (@noble/post-quantum) |
| Build Tool | Hardhat |
| Database | Supabase |

---

## Acknowledgements

Research on EVM-friendly post-quantum signatures. Built with OpenZeppelin, Thirdweb, Ethers.js, and Supabase.

---

## Disclaimer

This project is for educational purposes only. Ensure a proper security audit is conducted before deploying to mainnet with real economic value.
