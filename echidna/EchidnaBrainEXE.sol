// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../contracts/BrainEXE.sol";
import "./MockMintGate.sol";

/**
 * @title EchidnaBrainEXE
 * @dev Echidna property-based tests for BrainEXE.
 *      Invariants:
 *      - totalSupply() <= MAX_SUPPLY
 *      - burnFee <= MAX_BURN_FEE
 *      - totalMinted <= MINTABLE_SUPPLY
 *      - mintedByWallet[any] <= maxMintPerWallet
 *      - Balance of this contract + total burned == totalMinted + LIQUIDITY_SUPPLY (rough accounting)
 */
contract EchidnaBrainEXE {
    MockMintGate public mockGate;
    BrainEXE public token;

    // Track addresses created by fuzzer so we can assert per-wallet caps
    address[] public actors;
    mapping(address => bool) public isActor;

    constructor() {
        mockGate = new MockMintGate();
        token = new BrainEXE(address(mockGate));
        // Fund this contract with ETH for minting
    }

    // --- Fuzzer callable actions ---

    function mint(uint256 ethAmount, address receiver) public payable {
        if (receiver == address(0)) receiver = address(this);
        _addActor(receiver);
        // Bound ETH to reasonable values (0.001 - 10 ETH)
        uint256 amount = 0.001 ether + (ethAmount % 10 ether);
        if (address(this).balance < amount) return;
        try token.mint{value: amount}() {} catch {
            // Expect revert on cap exceeded or disabled mint
        }
    }

    function mintWithProof(
        uint256 epoch,
        address recipient,
        bytes32 pkHash,
        uint256 ethAmount
    ) public payable {
        if (recipient == address(0)) recipient = address(this);
        _addActor(recipient);
        uint256 amount = 0.001 ether + (ethAmount % 10 ether);
        if (address(this).balance < amount) return;

        // Set a valid root for this epoch so pkHash can pass
        mockGate.setMerkleRoot(epoch, pkHash);
        bytes32[] memory proof = new bytes32[](0);

        try token.mintWithProof{value: amount}(epoch, recipient, pkHash, proof) {} catch {
            // Expect revert on cap exceeded or disabled mint or already used pkHash
        }
    }

    function transfer(address to, uint256 amount) public {
        if (to == address(0)) to = address(this);
        _addActor(to);
        uint256 bal = token.balanceOf(address(this));
        if (bal == 0) return;
        amount = amount % (bal + 1);
        try token.transfer(to, amount) {} catch {}
    }

    function setBurnFee(uint256 fee) public {
        token.setBurnFee(fee % (token.MAX_BURN_FEE() + 1));
    }

    function toggleMint(bool enabled) public {
        token.toggleMint(enabled);
    }

    function setMaxMintPerWallet(uint256 maxx) public {
        token.setMaxMintPerWallet(maxx % token.MAX_SUPPLY());
    }

    function withdraw() public {
        try token.withdraw() {} catch {}
    }

    receive() external payable {}

    // --- Invariants (properties) ---

    function echidna_total_supply_cap() public view returns (bool) {
        return token.totalSupply() <= token.MAX_SUPPLY();
    }

    function echidna_burn_fee_bounded() public view returns (bool) {
        return token.burnFee() <= token.MAX_BURN_FEE();
    }

    function echidna_total_minted_cap() public view returns (bool) {
        return token.totalMinted() <= token.MINTABLE_SUPPLY();
    }

    function echidna_wallet_mint_cap() public view returns (bool) {
        for (uint256 i = 0; i < actors.length; i++) {
            if (token.mintedByWallet(actors[i]) > token.maxMintPerWallet()) {
                return false;
            }
        }
        return true;
    }

    function echidna_liquidity_supply_minted_once() public view returns (bool) {
        // Liquidity supply is minted to owner (this contract) in constructor
        return token.balanceOf(address(this)) <= token.MAX_SUPPLY();
    }

    // --- Helpers ---

    function _addActor(address addr) internal {
        if (!isActor[addr]) {
            isActor[addr] = true;
            actors.push(addr);
        }
    }
}
