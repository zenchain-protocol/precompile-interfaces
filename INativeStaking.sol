// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @dev The contract's address. */
address constant STAKING_ADDRESS = 0x0000000000000000000000000000000000000800;

/** @dev The contract's instance. */
NativeStaking constant STAKING_CONTRACT = NativeStaking(STAKING_ADDRESS);

interface NativeStaking {
    enum StakerStatus {
        Idle,
        Nominator,
        Validator,
        NotStaking
    }

    enum RewardDestination {
        Staked,
        Stash,
        None
    }

    struct Exposure {
        address who;
        uint value;
    }

    /*************************************************
     *                Transactions                   *
     *************************************************/

    /**
     * @notice Takes the origin account as a stash and locks up the specified value of its balance.
     * @dev The origin account becomes the stash account.
     * @param value Amount to bond.
     * @param dest Where the reward should go.
     */
    function bondWithRewardDestination(uint256 value, RewardDestination dest) external;

    /**
     * @notice Takes the origin account as a stash and locks up the specified value of its balance.
     * @dev The origin account becomes the stash account.
     * @param value Amount to bond.
     * @param payee Address to receive the rewards.
     */
    function bondWithPayeeAddress(uint256 value, address payee) external;

    /**
     * @notice Adds extra funds from the stash's free balance into the staking balance.
     * @dev Use this if there are additional funds in your stash account that you wish to bond.
     *      Unlike `bond` or `unbond`, this `function` does not have a limit on the amount added.
     * @param value The maximum additional amount to bond.
     */
    function bondExtra(uint256 value) external;

    /**
     * @notice Rebonds a portion of the stash scheduled to be unlocked.
     * @param value Amount to rebond.
     */
    function rebond(uint256 value) external;

    /**
     * @notice Schedules a portion of the stash to be unlocked after the bond period. The bond period can be retrieved with bondingDuration().
     * @dev Once the unlock period is done, you can call `withdrawUnbonded` to actually move the funds out of management.
     *      No more than a limited number of unlocking chunks (see `MaxUnlockingChunks`) can co-exist at the same time.
     *      If there are no unlocking chunk slots available, `withdrawUnbonded` is called to remove some of the chunks (if possible).
     *      If a user encounters the `InsufficientBond` error when calling this function, they should call `chill` first to free up their bonded funds.
     * @param value Amount to unbond.
     */
    function unbond(uint256 value) external;

    /**
     * @notice Removes unlocked chunks from the unlocking queue.
     * @dev This essentially frees up that balance to be used by the stash account to do whatever it wants.
     * @param numSlashingSpans Indicates the number of metadata slashing spans to clear when this call results in a complete removal of all the data related to the stash account.
     *      In this case, `numSlashingSpans` must be larger or equal to the number of slashing spans associated with the stash account in the `SlashingSpans` storage type, otherwise the call will fail.
     *      The call weight is directly proportional to `numSlashingSpans`.
     */
    function withdrawUnbonded(uint32 numSlashingSpans) external;

    /**
     * @notice Declares the desire to validate for the origin controller.
     * @dev Effects will be felt at the beginning of the next era.
     * @param commission Validator's commission perbill (10% = 0.1 * 10^9)
     * @param blocked Whether the validator is blocked.
     */
    function validate(uint32 commission, bool blocked) external;

    /**
     * @notice Declares the desire to nominate targets for the origin controller.
     * @dev Effects will be felt at the beginning of the next era.
     * @param targets Array of validator addresses to nominate.
     */
    function nominate(address[] calldata targets) external;

    /**
     * @notice Declares no desire to either validate or nominate.
     * @dev Effects will be felt at the beginning of the next era.
     */
    function chill() external;

    /**
     * @notice Resets the payment target for rewards.
     * @dev Rewards can either be restaked, sent to the staker's address or any custom address. Reverts if the caller is not staking.
            use setPayee for sending rewards to any custom address.
            use setRewardDestination for Restaking or sending rewards to Stash.
     * @param payee Address to receive the rewards.
     */
    function setPayee(address payee) external;

    /**
     * @notice Sets the destination for staking rewards.
      * @dev Rewards can either be restaked, sent to the staker's address or any custom address. Reverts if the caller is not staking.
        use setPayee for sending rewards to any custom address.
        use setRewardDestination for Restaking or sending rewards to Stash.
     * @param dest Destination for rewards. It can either be restaked, sent to stash, or burned.
     */
    function setRewardDestination(RewardDestination dest) external;

    /**
     * @notice Pays out a specific page of stakers behind a validator for a given era.
     * @dev Any account can call this function, even if it is not one of the stakers.
     *      If rewards are not claimed in `Config::HistoryDepth` eras, they are lost.
     * @param validatorStash Stash account of the validator.
     * @param era Era for which to payout rewards (between [current_era - history_depth; current_era]).
     * @param page Page index of nominators to pay out (between 0 and num_nominators / 64).
     */
    function payoutStakersByPage(address validatorStash, uint32 era, uint32 page) external;

    /**
     * @notice Kicks nominators from a validator's list.
     * @param nominators Addresses of the nominators to kick.
     */
    function kick(address[] calldata nominators) external;

    /**
     * @notice Chills another stash.
     * @param stash Address of the stash to chill.
     */
    function chillOther(address stash) external;

    /**
     * @notice Forces a validator to apply the minimum commission.
     * @param validatorStash Address of the validator stash.
     */
    function forceApplyMinCommission(address validatorStash) external;

    /**
     * @notice Adds a validator's stash account to the whitelist.
     * @dev Only callable by an authorized account (e.g., root/sudo).
     *      When the whitelist is enabled, only validators in this list can validate.
     * @param stash The stash address of the validator to add to the whitelist.
     */
    function addToValidatorWhitelist(address stash) external;

    /**
     * @notice Removes a validator's stash account from the whitelist.
     * @dev Only callable by an authorized account (e.g., root/sudo).
     * @param stash The stash address of the validator to remove from the whitelist.
     */
    function removeFromValidatorWhitelist(address stash) external;

    /**
     * @notice Enables or disables the validator whitelist.
     * @dev Only callable by an authorized account (e.g., root/sudo).
     *      If true, only whitelisted validators can validate. If false, any account can validate.
     * @param is_enabled Boolean flag to enable (true) or disable (false) the whitelist.
     */
    function setIsValidatorWhitelistEnabled(bool is_enabled) external;

    /*************************************************
     *                    Views                      *
     *************************************************/

    /**
     * @notice Returns the list of all validator addresses currently in the whitelist.
     * @return An array of addresses representing the validator whitelist.
     */
    function validatorWhitelist() external view returns (address[] memory);

    /**
     * @notice Returns whether the stash address is in the validator whitelist
     * @return Boolean indicating whether the given address is whitelisted
     */
    function isWhitelistedValidator(address stash) external view returns (bool);

    /**
     * @notice Returns whether the validator whitelist is enabled.
     * @return Boolean indicating whether the whitelist is enabled.
     */
    function isValidatorWhitelistEnabled() external view returns (bool);

    /**
     * @notice Returns the ideal validator count.
     * @return Ideal validator count.
     */
    function idealValidatorCount() external view returns (uint32);

    /**
     * @notice Returns the minimum validator count.
     * @return Minimum validator count.
     */
    function minValidatorCount() external view returns (uint32);

    /**
     * @notice Returns the list of invulnerable validators.
     * @return Array of invulnerable validator addresses.
     */
    function invulnerables() external view returns (address[] memory);

    /**
     * @notice Returns the minimum nominator bond.
     * @return Minimum nominator bond.
     */
    function minNominatorBond() external view returns (uint256);

    /**
     * @notice Returns the minimum validator bond.
     * @return Minimum validator bond.
     */
    function minValidatorBond() external view returns (uint256);

    /**
     * @notice Returns the minimum active nominator stake of the last successful election.
     * @return Minimum active stake.
     */
    function minActiveStake() external view returns (uint256);

    /**
     * @notice Returns the minimum validator commission.
     * @return Minimum validator commission.
     */
    function minValidatorCommissionPerbill() external view returns (uint256);

    /**
     * @notice Returns the reward payee of a given address.
     * @dev Returns address(0) if reward destination is restaking or stash.
     * @param who Address to check.
     * @return Address of the reward payee.
     */
    function payee(address who) external view returns (address);

    /**
     * @notice Returns the reward destination of a given address.
     * @dev Returns None if reward destination is custom payee address.
     *      If reward destination is None and custom payee address is address(0) than reward will be burned.
     * @param who Address to check.
     * @return Reward destination.
     */
    function rewardDestination(address who) external view returns (RewardDestination);

    /**
     * @notice Returns the validator preferences of a given address.
     * @dev Returns (0, false) if address is not validator, there isn't a way to differentiate between
     *      validators with 0 commission or address that's not validator with just this function.
     *      It should be used in conjunction with status to make sure address is validator
     * @param who Address to check.
     * @return commission Reward that validator takes up-front; only the rest is split between themselves and nominators.
     * @return blocked Whether or not this validator is accepting more nominations.
     */
    function validatorPrefs(address who) external view returns (uint256 commission, bool blocked);

    /**
     * @notice Returns the maximum validator count.
     * @return Maximum validator count.
     */
    function maxValidatorsCount() external view returns (uint32);

    /**
     * @notice Returns the nominator preferences of a given address.
     * @param who Address to check.
     * @return targets The validator targets of nomination.
     * @return submittedIn The era the nominations were submitted.
     * @return suppressed Whether the nominations have been suppressed.
     */
    function nominatorPrefs(address who) external view returns (address[] memory targets, uint32 submittedIn, bool suppressed);

    /**
     * @notice Returns the maximum nominator count.
     * @return Maximum nominator count.
     */
    function maxNominatorsCount() external view returns (uint32);

    /**
     * @notice Returns the current era index.
     * @dev This is the latest planned era, depending on how the Session pallet queues the validator set,
     *      it might be active or not.
     * @return Current era index.
     */
    function currentEra() external view returns (uint32);

    /**
     * @notice Returns the active era information.
     * @dev The active era is the era being currently rewarded.
     * @return Active era index
     */
    function activeEra() external view returns (uint32);

    /**
     * @notice The session index at which the era start for the last Config::HistoryDepth eras.
     * @dev This tracks the starting session (i. e. session index when era start being active)
     *      for the eras in [CurrentEra - HISTORY_DEPTH, CurrentEra].
     * @param eraIndex Era index to check.
     * @return Start session index.
     */
    function erasStartSessionIndex(uint32 eraIndex) external view returns (uint64);

    /**
     * @notice Returns the total stake and own stake for a given validator in a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @return totalStake Total stake for the validator.
     * @return ownStake Own stake for the validator.
     */
    function erasValidatorTotalStake(uint32 eraIndex, address validatorStash) external view returns (uint256 totalStake, uint256 ownStake);

    /**
     * @notice Returns the number of nominators and the number of pages for a given validator in a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @return numNominators Number of nominators for the validator.
     * @return numPages Number of pages of nominators.
     */
    function erasValidatorNominatorsCount(uint32 eraIndex, address validatorStash) external view returns (uint32 numNominators, uint32 numPages);

    /**
     * @notice Returns the total stake and own stake for a specific page of nominators behind a validator for a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @param pageIndex Page index of nominators to check.
     * @return Total stake for the page.
     */
    function erasValidatorNominationPageTotalExposure(
        uint32 eraIndex,
        address validatorStash,
        uint32 pageIndex
    ) external view returns (uint256);

    /**
     * @notice Returns the stake and address of a single nominator for a specific page of nominators behind a validator for a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @param pageIndex Page index of nominators to check.
     * @param nominationIndex Index of the nomination within the page to check.
     * @return nominatorStake Stake of the nominator.
     * @return nominatorAddress Address of the nominator.
     */
    function erasValidatorNominationPageNominatorExposure(
        uint32 eraIndex,
        address validatorStash,
        uint32 pageIndex,
        uint32 nominationIndex
    ) external view returns (
        uint256 nominatorStake,
        address nominatorAddress
    );

    /**
     * @notice Returns the claimed page index for rewards by a given validator in a specific era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @param index Index within the array of claimed pages.
     * @return claimedPageIndex Claimed page index.
     */
    function erasClaimedRewards(
        uint32 eraIndex,
        address validatorStash,
        uint32 index
    ) external view returns (
        uint32 claimedPageIndex
    );

    /**
     * @notice Returns the validator preferences of a given validator in a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @return commission Reward that validator takes up-front; only the rest is split between themselves and nominators.
     * @return blocked Whether or not this validator is accepting more nominations.
     */
    function erasValidatorPrefs(uint32 eraIndex, address validatorStash) external view returns (uint256 commission, bool blocked);

    /**
     * @notice Returns the total validator era payout for a given era.
     * @param eraIndex Era index to check.
     * @return Total validator era payout.
     */
    function erasValidatorPayout(uint32 eraIndex) external view returns (uint256);

    /**
     * @notice Returns the total reward points for a given era.
     * @param eraIndex Era index to check.
     * @return Total reward points.
     */
    function erasTotalRewardPoints(uint32 eraIndex) external view returns (uint32);

    /**
     * @notice Returns the reward points for a given validator in a given era.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @return Reward points.
     */
    function erasValidatorRewardPoints(uint32 eraIndex, address validatorStash) external view returns (uint32);

    /**
     * @notice Returns the total stake for a given era.
     * @param eraIndex Era index to check.
     * @return Total stake.
     */
    function erasTotalStake(uint32 eraIndex) external view returns (uint256);

    /**
     * @notice Returns the list of nominators with paged rewards for the given era, validator, and page.
     * This can be used to determine which page a nominator is on.
     * @param eraIndex Era index to check.
     * @param validatorStash Address of the validator stash.
     * @param page The page to retrieve.
     * @return page of nominators.
     */
    function erasStakersPage(uint32 eraIndex, address validatorStash, uint32 page) external view returns (Exposure[] memory);

    /**
     * @notice Returns the maximum staked rewards percentage. The percentage of the era inflation that is used for stake rewards.
     * @return Maximum staked rewards percentage.
     */
    function maxStakedRewardsPercent() external view returns (uint8);

    /**
     * @notice Returns the slash reward fraction. The percentage of the slash that is distributed to reporters.
     * @return Slash reward fraction.
     */
    function slashRewardFractionPerbill() external view returns (uint64);

    /**
     * @notice Returns the cancelled slash payout. The amount of currency given to reporters of a slash event which was canceled by extraordinary
     * @return Cancelled slash payout.
     */
    function cancelledSlashPayout() external view returns (uint256);

    /**
     * @notice Returns the last planned session index.
     * @return lastPlannedSessionIndex Index of the last planned session.
     */
    function currentPlannedSession() external view returns (
        uint32 lastPlannedSessionIndex
    );

    /**
     * @notice Checks if an account is in the process of unbonding.
     * @param who Address of the account to check.
     * @return True if the account is unbonding, false otherwise.
     */
    function isUnbonding(address who) external view returns (bool);

    /**
     * @notice Checks the staking status of an account.
     * @param who Address of the account to check.
     * @return Staker status.
     */
    function status(address who) external view returns (StakerStatus);

    /**
     * @notice Check how much currency is staked by the account. This method returns both the total and active amounts staked.
     * The total amount includes funds in the process of unbonding. The active amount excludes those funds.
     * In other words, the active amount only includes funds that will affect forthcoming rounds.
     * @param who Address of the account to check.
     * @return total staked amounts.
     * @return active staked amounts.
     */
    function stake(address who) external view returns (uint256 total, uint256 active);

    /**
     * @notice Checks whether an account is/was exposed in a specific era.
     * @dev An "exposed" staker is one who actively backed any validators during the given era.
     * @param who The Ethereum address representing the stash account of the staker to check.
     * @param era The era index to check for exposure. Must be within the range of eras stored in history (i.e., between `currentEra() - historyDepth()` and `currentEra()`).
     * @return Returns `true` if the staker was exposed in the given era, `false` otherwise.
     */
    function isExposedInEra(address who, uint32 era) external view returns (bool);

    /**
    * @notice Checks if an account is bonded.
    * @param who The address of the account to check.
    * @return true if the account is bonded; false otherwise.
    */
    function bonded(address who) external view returns (bool);

    /*************************************************
     *                   Constants                   *
     *************************************************/

    /**
    * @notice The eras in the set [current_era - history_depth; current_era] are stored in history.
    * @return Number of eras to keep in history
    */
    function historyDepth() external view returns (uint32);

    /**
     * @notice Returns the number of sessions per era.
     * @return Number of sessions per era.
     */
    function sessionsPerEra() external view returns (uint32);

    /**
     * @notice Returns the bonding duration as the number of eras.
     * @return Bonding duration.
     */
    function bondingDuration() external view returns (uint32);

    /**
     * @notice Returns the number of sessions per era.
     * @return Number of sessions per era.
     */
    function slashDeferDuration() external view returns (uint32);

    /**
     * @notice Returns the maximum size of each ExposurePage.
     * @return Maximum size of each ExposurePage
     */
    function maxExposurePageSize() external view returns(uint32);

    /**
     * @notice Returns the maximum number of unlocking chunks a StakingLedger can have. Effectively determines how many unique eras a staker may be unbonding in.
     * @return Maximum number of unlocking chunks a StakingLedger can have
     */
    function maxUnlockingChunks() external view returns(uint32);

    /*************************************************
     *                  Initializers                 *
     *************************************************/

    /**
     * @notice Populates the precompile address with dummy bytecode.
     * @dev Allows wallets like Metamask to recognize the precompile as a contract.
     */
    function populateBytecode() external;
}