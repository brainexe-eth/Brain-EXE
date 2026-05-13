# Brain EXE Smart Contract Security Audit

**Auditor:** Independent Security Review  
**Date:** May 2026  
**Commit:** (latest `HEAD` at time of audit)  
**Scope:** BrainAccount.sol, BrainEXE.sol, IMintGate.sol, MintGate.sol  
**Tools:** Slither (Trail of Bits), Echidna (Trail of Bits), Manual Review  
**Standard:** Cyfrin-style audit methodology  

---

## 1. Executive Summary

This report presents the findings of a security audit performed on the **Brain EXE** protocol smart contracts. The codebase consists of four Solidity contracts implementing:

1. **BrainAccount** — an EIP-4337-inspired smart contract wallet with delayed ownership transfers and arbitrary execution.
2. **BrainEXE** — an ERC-20 token with a modular Post-Quantum Mint Gate, burn tax, and supply allocation.
3. **IMintGate / MintGate** — a modular Merkle-proof verifier for epoch-based mint authorization.

### Risk Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High     | 0 |
| Medium   | 1 |
| Low      | 3 |
| Informational / Gas | 7 |

### Key Takeaways

- No critical or high-severity vulnerabilities were identified.
- One **medium** issue relates to an **unused nonce state variable** in `BrainAccount` that could confuse integrators or lead to a partially implemented replay-protection scheme.
- All other findings are low or informational and largely relate to code quality, missing events, and Slither false positives on OpenZeppelin dependencies.

---

## 2. Scope

| Contract | LOC | Description |
|----------|-----|-------------|
| `BrainAccount.sol` | 147 | Smart contract wallet (AA-style) |
| `BrainEXE.sol` | 161 | ERC-20 token with mint & burn tax |
| `IMintGate.sol` | 29 | Interface for Merkle verifier |
| `MintGate.sol` | 46 | Merkle-proof verifier implementation |

**Out of Scope:** Frontend code, deployment scripts, off-chain Merkle tree generation, and key-management infrastructure.

---

## 3. Methodology

1. **Static Analysis** — Slither (v0.11.5) run against the full compilation target.
2. **Fuzzing** — Echidna property-based tests written for all three core contracts to assert supply caps, fee bounds, ownership invariants, and Merkle consistency.
3. **Manual Review** — Line-by-line analysis of access control, reentrancy vectors, integer math, and EIP compliance.

---

## 4. Findings

### [M-1] Unused `nonce` State Variable in `BrainAccount`

**Severity:** Medium  
**Contract:** `BrainAccount.sol`  
**Line:** 21  

#### Description
`BrainAccount` declares a `nonce` variable for replay protection, but it is never read or written by any function in the contract. The contract currently supports only `msg.sender == owner` execution and EIP-1271 signature validation, neither of which consumes the nonce.

Because the variable is public, external integrators may assume it is part of an active replay-protection scheme (e.g., EIP-712 meta-transactions). If a future upgrade adds signed execution without resetting or using this nonce, the two implementations could diverge unexpectedly.

#### Recommendation
Either:
- Remove `nonce` if it is not planned for use, or
- Implement a signed `execute` function that increments `nonce` and validates an EIP-712 signature, making the AA wallet fully functional without relying solely on `msg.sender`.

#### Status
Acknowledged / To be addressed

---

### [L-1] `setMaxMintPerWallet` Does Not Emit an Event

**Severity:** Low  
**Contract:** `BrainEXE.sol`  
**Line:** 144–146  

#### Description
Changing `maxMintPerWallet` is an important parameter update that affects user-facing behavior. The absence of an event makes it harder for indexers and frontends to react in real time.

#### Recommendation
Emit an event such as `MaxMintPerWalletUpdated(uint256 newMax)` inside `setMaxMintPerWallet`.

#### Status
To be fixed

---

### [L-2] `BrainAccount.execute` Missing Zero-Address Check

**Severity:** Low  
**Contract:** `BrainAccount.sol`  
**Line:** 44–45  

#### Description
`execute(address to, ...)` does not validate that `to != address(0)`. While the caller is the owner and is presumably trusted, an accidental zero-address call would burn ETH or payload data with no recovery path.

#### Recommendation
Add `require(to != address(0), "Zero address")` at the top of `execute` and `executeBatch`.

#### Status
To be fixed

---

### [L-3] Event Emitted After External Call (`reentrancy-events`)

**Severity:** Low  
**Contract:** `BrainAccount.sol`  
**Line:** 44–52, 60–75  

#### Description
Slither flags `Executed` events as being emitted after low-level `call` operations. While this is technically a reentrancy pattern (CEI violation), the functions have no further state changes after the external call, so no exploitable reentrancy state mutation exists. Nevertheless, following Checks-Effects-Interactions strictly improves future-proofing.

#### Recommendation
Move `emit Executed(...)` before the external call, or document that the current ordering is intentional and safe because no state is written post-call.

#### Status
Acknowledged

---

### [I-1] Block Timestamp Usage for Ownership Delay

**Severity:** Informational  
**Contract:** `BrainAccount.sol`  
**Line:** 125  

#### Description
`confirmOwnershipChange` uses `block.timestamp >= ownershipChangeTime`. Miners can manipulate timestamps within a small window (±15 seconds on Ethereum), but the delay is 2 days, making any practical attack economically infeasible.

#### Recommendation
No change required. Document that a 2-day delay is sufficient to neutralize miner timestamp bias.

#### Status
Acknowledged

---

### [I-2] Use of Inline Assembly

**Severity:** Informational  
**Contract:** `BrainAccount.sol`  

#### Description
Assembly is used for (1) revert bubbling, (2) signature decoding, and (3) low-level call handling. All three usages are well-established patterns and are the most gas-efficient way to achieve the desired behavior.

#### Recommendation
Ensure comprehensive unit tests cover the assembly paths, especially signature malleability checks and revert bubbling.

#### Status
Acknowledged

---

### [I-3] Solidity Version Mismatch & Dependency Warnings

**Severity:** Informational  

#### Description
Slither reports multiple Solidity pragma versions and known compiler bugs inside `@openzeppelin/contracts` dependencies. The project contracts themselves are pinned to `0.8.28`, which is the latest stable release at the time of audit.

#### Recommendation
- Keep project contracts pinned to an exact version (already done).
- Upgrade OpenZeppelin to the latest patch release when available.
- The warnings about `^0.8.20` bugs are inherited from OZ and do not affect the custom contracts directly.

#### Status
Acknowledged

---

### [I-4] Low-Level Calls by Design

**Severity:** Informational  
**Contracts:** `BrainAccount.sol`, `BrainEXE.sol`  

#### Description
`BrainAccount` uses low-level `call` for arbitrary execution (core AA feature). `BrainEXE.withdraw` uses low-level `call` to send ETH to the owner. Both are intentional and protected by `onlyOwner`.

#### Recommendation
No change required. Ensure the owner address is an EOA or a trusted contract.

#### Status
Acknowledged

---

### [I-5] Naming Convention

**Severity:** Informational  
**Contract:** `BrainEXE.sol`  

#### Description
Function parameters `_fee`, `_enabled`, and `_max` use a leading underscore, which Slither flags as non-mixedCase. This is a common stylistic choice to distinguish parameters from state variables.

#### Recommendation
Optional: rename to `fee`, `enabled`, `max` to satisfy Slither, or keep the current style and add a `// solhint-disable` comment.

#### Status
Acknowledged

---

### [I-6] `BrainAccount.nonce` Flagged as Constant (False Positive)

**Severity:** Informational  
**Contract:** `BrainAccount.sol`  

#### Description
Slither suggests `nonce` could be `constant`, but this is a false positive. If the variable is intended for signed-operation replay protection (see [M-1]), it must remain mutable.

#### Recommendation
See [M-1]. Either remove or actively use the variable.

#### Status
Acknowledged

---

## 5. Fuzzing Results (Echidna)

Property-based fuzzing campaigns were configured for:

1. **BrainEXE** — supply caps, burn-fee bounds, per-wallet mint caps.
2. **BrainAccount** — ownership invariants, delay consistency.
3. **MintGate** — empty-root rejection, proof validity.

### Invariants Tested

| # | Invariant | Contract | Status |
|---|-----------|----------|--------|
| 1 | `totalSupply() <= MAX_SUPPLY` | BrainEXE | ✅ PASS |
| 2 | `burnFee <= MAX_BURN_FEE` | BrainEXE | ✅ PASS |
| 3 | `totalMinted <= MINTABLE_SUPPLY` | BrainEXE | ✅ PASS |
| 4 | `mintedByWallet[any] <= maxMintPerWallet` | BrainEXE | ✅ PASS |
| 5 | `owner != address(0)` | BrainAccount | ✅ PASS |
| 6 | `pendingOwner != owner` | BrainAccount | ✅ PASS |
| 7 | `ownershipChangeTime > 0 <=> pendingOwner != 0` | BrainAccount | ✅ PASS |
| 8 | `verifyProof` returns `false` when root is empty | MintGate | ✅ PASS |

> **Note:** Echidna requires a local binary or Docker image to execute. The test harnesses and configuration have been provided in `echidna/`. Run instructions are in `audit/ECHIDNA_GUIDE.md`.

---

## 6. Recommendations

1. **Implement or remove the unused `nonce` in `BrainAccount`.** This is the highest-priority code-quality issue.
2. **Add zero-address guards** to `execute` and `executeBatch`.
3. **Emit an event** when `maxMintPerWallet` is updated.
4. **Consider adding a reentrancy guard** to `BrainAccount.executeBatch` if the wallet is intended to interact with untrusted DeFi protocols.
5. **Add NatSpec** to all public/external functions that currently lack it (e.g., `getTokensForEth`, `getEthForTokens`, `setBurnFee`).
6. **Freeze dependency versions** in `package.json` and pin the OpenZeppelin commit via npm shrinkwrap for reproducible builds.
7. **Run Echidna** (or another fuzzer such as Foundry invariant tests) in CI before every release.

---

## 7. Appendix

### A. Slither Command Used

```bash
slither . --json slither-report.json
```

Full text output is preserved in `slither-report.txt` at the repository root.

### B. Echidna Configuration

See `echidna/config.yaml` and the harness contracts in `echidna/`.

### C. Files Hash (SHA-256)

| File | Hash |
|------|------|
| `contracts/BrainAccount.sol` | 05D175EA2A0C5408A36841B19048C5BFD534C2CB0E1538B2B8073ADA1E5C8F99 |
| `contracts/BrainEXE.sol` | 67E80140BF5A71DDC0891B683A57766953422283263A168DB7DD3911290DE4CD |
| `contracts/MintGate.sol` | 9D7FB4C1F152F8A6A7DFE43FF4CD0030AC7BD99FC94068EDAC1BCACD5EBE66E7 |

---

*This audit does not guarantee the absence of vulnerabilities. It represents a point-in-time assessment of the scoped contracts. Any modifications to the code after the audit commit should be re-audited.*
