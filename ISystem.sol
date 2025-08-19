pragma solidity ^0.8.0;

/** @dev The contract's address. */
address constant SYSTEM_ADDRESS = 0x0000000000000000000000000000000000000808;

/** @dev The contract's instance. */
System constant SYSTEM_CONTRACT = System(SYSTEM_ADDRESS);

interface System {

    /**
     * @dev Emitted when a new runtime has been successfully applied.
     * This event is typically triggered by `setCode` or `applyAuthorizedUpgrade`.
     */
    event NewRuntime(bytes32 indexed codeHash);

    /**
     * @dev Emitted when a runtime upgrade has been authorized.
     * @param codeHash The hash of the authorized runtime code.
     */
    event RuntimeUpgradeAuthorized(bytes32 indexed codeHash);

    /**
     * @dev Emitted when a finalization stall has been noted.
     * @param delay The delay in blocks before the new authority set is enacted. The count starts at the beginning of the next session.
     * @param bestFinalizedBlockNumber The best finalized block number to build upon.
     */
    event FinalizationStallNoted(uint32 delay, uint32 bestFinalizedBlockNumber);

    /**
     * @notice Authorize an upgrade to a given codeHash for the runtime. The runtime can be supplied later.
     * @dev This function allows a root user to authorize a future runtime upgrade by specifying the hash of the new runtime code. The actual runtime code can be provided later using `applyAuthorizedUpgrade`. This call requires Root origin.
     * @param codeHash The hash of the Wasm binary for the new runtime code.
     */
    function authorizeUpgrade(bytes32 codeHash) external;

    /**
     * @notice Provide the preimage (runtime binary) code for an upgrade that has been authorized.
     * @dev This function allows any user to provide the preimage (runtime binary) for an upgrade that has been previously authorized via `authorizeUpgrade`.
     * If the authorization required a version check, this call will ensure the spec name remains unchanged and that the spec version has increased.
     * Depending on the runtime’s OnSetCode configuration, this function may directly apply the new code in the same block or attempt to schedule the upgrade.
     * All origins are allowed to call this.
     * @param code The Wasm binary of the new runtime code.
     */
    function applyAuthorizedUpgrade(bytes calldata code) external;

    /**
     * @notice Sets the new runtime code for the blockchain.
     * @dev Calling this function will replace the current runtime with the new provided code. This call requires Root origin.
     * @param code The Wasm binary of the new runtime code.
     */
    function setCode(bytes calldata code) external;

    /**
     * @notice Notes that the GUARDIAN finality gadget has stalled, triggering a forced authority set change.
     * @dev When the current authority set of the finality gadget stalls, this function can be called to trigger a forced authority set change at the beginning of the next session. This change will be enacted after a specified `delay` in blocks. The new authority set will then start voting on top of the provided `bestFinalizedBlockNumber`. This call requires Root origin.
     * @param delay The number of blocks to delay the enactment of the new authority set. This should be a value high enough to avoid re-orgs (e.g., 1000 blocks). The count starts at the beginning of the next session.
     * @param bestFinalizedBlockNumber The highest finalized block number agreed upon by the validators of the new authority set.
     */
    function noteStalled(uint32 delay, uint32 bestFinalizedBlockNumber) external;

    // View functions

    /**
     * @notice Checks for a pending authorized runtime upgrade. To get the code hash of an authorized upgrade, check the latest RuntimeUpgradeAuthorized event.
     * @return True if an upgrade has been authorized, false otherwise.
     */
    function authorizedUpgrade() external view returns (bool);

    /**
     * @notice Retrieves the spec version of the last successful runtime upgrade.
     * @return The spec version of the last applied runtime.
     */
    function lastRuntimeUpgradeSpecVersion() external view returns (uint32);

    /**
     * @notice Indicates whether the GUARDIAN finality gadget is currently stalled.
     * @dev A stall occurs if finality has not progressed for a defined period.
     * @return `true` if the finality gadget is stalled, otherwise `false`.
     */
    function stalled() external view returns (bool);

    /**
     * @notice If a stall has been reported, this returns the block number when a forced change of GUARDIAN authorities will occur.
     * @return The block number for the next forced authority set change. Returns 0 if no forced change is scheduled.
     */
    function nextForced() external view returns (uint32);

    /**
    * @dev Populates the precompile address with dummy bytecode, allowing the precompile to pass related checks.
    * For example, the presence of bytecode allows wallets like Metamask to recognize the precompile as a contract.
    * This is only callable by the root user.
    */
    function populateBytecode() external;
}
