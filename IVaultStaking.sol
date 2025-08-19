pragma solidity ^0.8.0;

/** @dev The contract's address. */
address constant VAULT_STAKING_ADDRESS = 0x0000000000000000000000000000000000000805;

/** @dev The contract's instance. */
VaultStaking constant VAULT_STAKING_CONTRACT = VaultStaking(VAULT_STAKING_ADDRESS);

/** The VaultStaking precompile interface */
interface VaultStaking {

    /**
     * @title Vault
     * @dev Represents a ZenVault smart contract in the vault staking system.
     * @notice This struct stores all essential information about a registered ZenVault.
     */
    struct Vault {
        /**
         * @dev The smart contract address of the ZenVault.
         * @notice This is the primary identifier for the vault in the system.
         */
        address _address;

        /**
         * @dev The address of the associated liquidity pool.
         * @notice This address serves as both the liquidity pair contract and the LP token address.
         * @notice Used for measuring liquidity positions.
         */
        address poolAddress;

        /**
         * @dev The address of the non-native token in the liquidity pool.
         */
        address tokenAddress;

        /**
         * @dev The account designated to receive staking rewards.
         * @notice All network staking rewards earned by this vault are first sent to this account. The balance of this account can be distributed to ZenVault smart contract stakers.
         */
        address rewardAccount;

        /**
         * @dev The combined value of bonded tokens and native currency in the vault.
         * @notice This value represents the total economic stake of the vault and is used for
         * reward calculations and slash determinations.
         */
        uint128 virtualBond;

        /**
         * @dev The era number when this vault was last updated.
         * @notice Used to track when the vault's state was last synchronized with
         * the underlying staking system.
         */
        uint32 lastUpdate;
    }

    /**
     * @title PendingSlash
     * @dev Represents a slash that has been recorded but not yet applied to a vault.
     * @notice When the direct application of a slash fails, a pending slash stored for later application.
     */
    struct PendingSlash {
        /**
         * @dev The total amount, in native currency, being slashed from the vault.
         * @notice This represents the penalty amount determined by the staking system
         * for validator misbehavior or other slashable offenses.
         */
        uint128 slashedTotal;

        /**
         * @dev The vault's virtual bond before the slash is applied.
         * @notice This value is stored to accurately calculate the percentage impact
         * of the slash and to enable proper accounting during slash application.
         */
        uint128 balanceBeforeSlash;
    }

    /**
     * @notice Updates the state of a vault based on staking changes.
     * @dev Synchronizes the vault's virtual bond with the current state of the underlying staking system.
     *      This function must be called each era to ensure the vault's state remains accurate,
     *      especially after new nominations or changes in the staking network.
     *      An updated vault ensures accurate reward calculations and proper slash processing.
     * @param vaultAddress The address of the vault to update (must be a registered ZenVault).
     * @custom:throws VaultNotFound if the specified vault is not registered in the system.
     */
    function updateVault(address vaultAddress) external;

    /**
     * @notice Distributes rewards for a specific vault.
     * @dev Transfers accumulated staking rewards from the reward account to the ZenVault contract.
     * @param vaultAddress The address of the vault to distribute rewards for.
     * @custom:throws VaultNotFound if the specified vault is not registered.
     * @custom:throws NoPendingEraRewards if there are no rewards to distribute.
     */
    function distributeRewards(address vaultAddress) external;

    /**
     * @notice Applies any pending slash for a specific vault.
     * @dev Requires root privileges.
     * @param vaultAddress The address of the vault to apply the pending slash for.
     */
    function applyPendingSlash(address vaultAddress) external;

    /**
     * @notice Registers a new vault.
     * @dev Requires root privileges.
     * @param vaultAddress The address of the vault to register.
     */
    function registerVault(address vaultAddress) external;

    /**
     * @notice Deregisters an existing vault.
     * @dev Requires root privileges.
     * @param vaultAddress The address of the vault to deregister.
     */
    function deregisterVault(address vaultAddress) external;

    /**
     * @notice Sets the nomination targets for a vault.
     * @dev Requires root privileges.
     * @param vaultAddress The address of the vault.
     * @param nominationTargets The list of addresses to nominate.
     */
    function setNominations(address vaultAddress, address[] calldata nominationTargets) external;

    // --- View Functions ---

    /**
     * @notice Returns the details of a specific vault.
     * @dev Fetches comprehensive information about a registered vault from storage.
     *      This function will revert with a VaultNotFound error if the requested vault
     *      is not registered in the system.
     * @param vaultAddress The address of the vault to query.
     * @return vault A Vault struct containing all vault details including:
     *         - _address: The smart contract address of the ZenVault
     *         - poolAddress: The associated liquidity pool address
     *         - tokenAddress: The address of the non-native token in the associated liquidity pool.
     *         - rewardAccount: The account receiving staking rewards
     *         - virtualBond: The total economic stake (bonded tokens + native currency)
     *         - lastUpdate: The era number when this vault was last synchronized
     * @custom:throws VaultNotFound If the specified vault does not exist.
     */
    function vaults(address vaultAddress) external view returns (Vault memory vault);

    /**
     * @notice Returns a complete list of all registered vaults in the system.
     * @dev This function performs a full enumeration of all vaults stored in the system.
     *      It retrieves comprehensive information about each registered vault, converting
     *      from the internal storage format to the Solidity-compatible Vault structs.
     *
     *      Since this operation scans the entire vault storage, it has gas costs that
     *      scale linearly with the number of registered vaults. Be cautious when using
     *      this function if there could be a large number of vaults.
     *
     * @return An array of Vault structs, each containing complete details about a registered vault:
     *         - _address: The smart contract address of the ZenVault
     *         - poolAddress: The associated liquidity pool address
     *         - tokenAddress: The non-native token address in the liquidity pool
     *         - rewardAccount: The account receiving staking rewards
     *         - virtualBond: The total economic stake (bonded tokens + native currency)
     *         - lastUpdate: The era number when the vault was last synchronized
     */
    function getAllVaults() external view returns (Vault[] memory);

    /**
     * @notice Returns the pending slashes for a specific vault.
     * @dev Retrieves all pending slashes that have been recorded but not yet applied.
     *      When the direct application of a slash fails, it is stored as pending for later
     *      application through the applyPendingSlash function.
     * @param vaultAddress The address of the vault to query.
     * @return slashes An array of PendingSlash structs, each containing:
     *         - slashedTotal: The total amount being slashed from the vault
     *         - balanceBeforeSlash: The vault's virtual bond before the slash
     * @custom:throws VaultNotFound If the specified vault does not exist.
     */
    function pendingSlashes(address vaultAddress) external view returns (PendingSlash[] memory slashes);

    /**
     * @notice Returns the last era index when vault bond updates were processed.
     * @dev This value tracks the most recent era during which the vault system was
     *      synchronized with the underlying staking system.
     *      Used internally to determine when new updates need to be processed.
     * @return eraIndex The last update era index as a uint32.
     */
    function lastBondUpdateEra() external view returns (uint32 eraIndex);

    /**
     * @notice Returns the queue of vaults pending bond updates.
     * @dev This queue tracks vaults that need to be synchronized with the underlying
     *      staking system in the next processing cycle.
     *      Vaults are added to this queue once per era.
     *      The queue is automatically processed once per era.
     * @return queue An array of vault addresses that are waiting to be updated.
     */
    function vaultBondUpdateQueue() external view returns (address[] memory queue);

    // --- System Functions ---

    /**
    * @dev Populates the precompile address with dummy bytecode, allowing the precompile to pass related checks.
    * For example, the presence of bytecode allows wallets like Metamask to recognize the precompile as a contract.
    */
    function populateBytecode() external;
}
