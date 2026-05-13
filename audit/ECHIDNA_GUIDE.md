# Echidna Fuzzing Guide for Brain EXE

## Prerequisites

1. **Docker** (recommended) OR the Echidna binary installed locally.
2. **Solc** 0.8.28 installed via `solc-select`.

### Install Echidna via Docker

```bash
docker pull trailofbits/echidna
```

### Install Echidna Binary (Linux / macOS / WSL)

Download the latest release from:  
https://github.com/crytic/echidna/releases

```bash
tar -xvf echidna-*.tar.gz
sudo mv echidna /usr/local/bin/
```

---

## Project Structure

```
echidna/
├── MockMintGate.sol
├── EchidnaBrainEXE.sol
├── EchidnaBrainAccount.sol
├── EchidnaMintGate.sol
└── config.yaml
```

---

## Running the Campaigns

### 1. BrainEXE Token Invariants

```bash
echidna echidna/EchidnaBrainEXE.sol \
  --contract EchidnaBrainEXE \
  --config echidna/config.yaml \
  --solc-args "--base-path . --include-path node_modules"
```

### 2. BrainAccount Wallet Invariants

```bash
echidna echidna/EchidnaBrainAccount.sol \
  --contract EchidnaBrainAccount \
  --config echidna/config.yaml \
  --solc-args "--base-path . --include-path node_modules"
```

### 3. MintGate Verifier Invariants

```bash
echidna echidna/EchidnaMintGate.sol \
  --contract EchidnaMintGate \
  --config echidna/config.yaml \
  --solc-args "--base-path . --include-path node_modules"
```

---

## Interpreting Results

- **Green (`echidna_` property passed)** — the invariant held for all fuzzed sequences.
- **Red (`echidna_` property failed)** — Echidna found a counter-example. Inspect the sequence in the output to reproduce the bug.
- **Coverage** — after the run, check the `echidna-corpus/` directory for covered code paths.

---

## Extending the Tests

Add new action functions (no `echidna_` prefix) to mutate state, and new `echidna_*` view functions to assert invariants.

Example:

```solidity
function echidna_my_new_invariant() public view returns (bool) {
    return token.totalSupply() >= token.totalMinted();
}
```

---

## Tips

- Increase `testLimit` or `campaignTimeout` in `config.yaml` for deeper exploration.
- Use `crytic-compile` integration if your project uses Hardhat:
  ```bash
  echidna . --contract EchidnaBrainEXE --config echidna/config.yaml
  ```
  (requires `crytic-compile` to detect Hardhat automatically).
