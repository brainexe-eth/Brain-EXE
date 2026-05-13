// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../contracts/IMintGate.sol";

/**
 * @dev Mock MintGate for Echidna fuzzing.
 *      Allows setting arbitrary roots so the fuzzer can explore both valid and invalid proofs.
 */
contract MockMintGate is IMintGate {
    mapping(uint256 => bytes32) public merkleRoots;

    function setMerkleRoot(uint256 epoch, bytes32 root) external {
        merkleRoots[epoch] = root;
    }

    function verifyProof(
        uint256 epoch,
        bytes32 leaf,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 root = merkleRoots[epoch];
        if (root == bytes32(0)) return false;
        // Simplified: for fuzzing we treat root == leaf as valid when no proof provided,
        // otherwise we do a real verification if proof length > 0.
        if (merkleProof.length == 0) {
            return leaf == root;
        }
        // In a real setup we would use MerkleProof.verify; here we keep it simple
        // to allow the fuzzer to control validity via setMerkleRoot.
        return _verify(merkleProof, root, leaf);
    }

    function _verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}
