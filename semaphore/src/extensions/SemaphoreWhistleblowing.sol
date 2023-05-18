//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ISemaphoreWhistleblowing.sol";
import "../interfaces/ISemaphoreVerifier.sol";
import "../base/SemaphoreGroups.sol";

/// @title Semaphore whistleblowing contract.
/// @dev The following code allows you to create entities for whistleblowers (e.g. non-profit
/// organization, newspaper) and to allow them to publish news leaks anonymously.
/// Leaks can be IPFS hashes, permanent links or other kinds of reference.
contract SemaphoreWhistleblowing is ISemaphoreWhistleblowing, SemaphoreGroups {
    ISemaphoreVerifier public verifier;

    /// @dev Gets an editor address and return their entity.
    mapping(address => uint256) private entities;

    /// @dev Checks if the editor is the transaction sender.
    /// @param entityId: Id of the entity.
    modifier onlyEditor(uint256 entityId) {
        if (entityId != entities[_msgSender()]) {
            revert Semaphore__CallerIsNotTheEditor();
        }

        _;
    }

    /// @dev Initializes the Semaphore verifier used to verify the user's ZK proofs.
    /// @param _verifier: Semaphore verifier address.
    constructor(ISemaphoreVerifier _verifier) {
        verifier = _verifier;
    }

    /// @dev See {ISemaphoreWhistleblowing-createEntity}.
    function createEntity(
        uint256 entityId,
        address editor,
        uint256 merkleTreeDepth
    ) public override {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert Semaphore__MerkleTreeDepthIsNotSupported();
        }

        _createGroup(entityId, merkleTreeDepth, 0);

        entities[editor] = entityId;

        emit EntityCreated(entityId, editor);
    }

    /// @dev See {ISemaphoreWhistleblowing-addWhistleblower}.
    function addWhistleblower(uint256 entityId, uint256 identityCommitment) public override onlyEditor(entityId) {
        _addMember(entityId, identityCommitment);
    }

    /// @dev See {ISemaphoreWhistleblowing-removeWhistleblower}.
    function removeWhistleblower(
        uint256 entityId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public override onlyEditor(entityId) {
        _removeMember(entityId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev See {ISemaphoreWhistleblowing-publishLeak}.
    function publishLeak(
        uint256 leak,
        uint256 nullifierHash,
        uint256 entityId,
        uint256[8] calldata proof
    ) public override {
        uint256 merkleTreeDepth = getMerkleTreeDepth(entityId);
        uint256 merkleTreeRoot = getMerkleTreeRoot(entityId);

        verifier.verifyProof(merkleTreeRoot, nullifierHash, leak, entityId, proof, merkleTreeDepth);

        emit LeakPublished(entityId, leak);
    }
}
