// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../contracts/BrainAccount.sol";

/**
 * @title EchidnaBrainAccount
 * @dev Echidna property-based tests for BrainAccount.
 *      Invariants:
 *      - Owner cannot be address(0)
 *      - pendingOwner is either address(0) or not equal owner
 *      - ownershipChangeTime > 0 iff pendingOwner != address(0)
 *      - Only owner can execute
 */
contract EchidnaBrainAccount {
    BrainAccount public account;
    address public ownerAddr;

    constructor() {
        ownerAddr = address(this);
        account = new BrainAccount(ownerAddr);
    }

    // --- Fuzzer callable actions ---

    function execute(address to, uint256 value, bytes calldata data) public {
        // Only owner should succeed
        account.execute(to, value, data);
    }

    function executeBatch(address[] calldata to, uint256[] calldata value, bytes[] calldata data) public {
        account.executeBatch(to, value, data);
    }

    function initiateOwnershipChange(address newOwner) public {
        account.initiateOwnershipChange(newOwner);
    }

    function confirmOwnershipChange() public {
        account.confirmOwnershipChange();
    }

    function cancelOwnershipChange() public {
        account.cancelOwnershipChange();
    }

    receive() external payable {}

    // --- Invariants ---

    function echidna_owner_not_zero() public view returns (bool) {
        return account.owner() != address(0);
    }

    function echidna_pending_owner_not_current_owner() public view returns (bool) {
        return account.pendingOwner() != account.owner();
    }

    function echidna_ownership_time_consistency() public view returns (bool) {
        // If pendingOwner is zero, ownershipChangeTime must be zero
        if (account.pendingOwner() == address(0)) {
            return account.ownershipChangeTime() == 0;
        }
        // If pendingOwner is non-zero, ownershipChangeTime must be in the future
        return account.ownershipChangeTime() > 0;
    }

    function echidna_delay_constant() public view returns (bool) {
        return account.OWNERSHIP_DELAY() == 2 days;
    }
}
