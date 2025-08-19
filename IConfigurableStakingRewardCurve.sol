pragma solidity ^0.8.0;

/** @dev The contract's address. */
address constant CONFIGURABLE_STAKING_REWARD_CURVE_ADDRESS = 0x0000000000000000000000000000000000000807;

/** @dev The contract's instance. */
ConfigurableStakingRewardCurve constant CONFIGURABLE_STAKING_REWARD_CURVE_CONTRACT = ConfigurableStakingRewardCurve(CONFIGURABLE_STAKING_REWARD_CURVE_ADDRESS);

interface ConfigurableStakingRewardCurve {

    event NewRewardCurve(
        uint32 minInflation,
        uint32 maxInflation,
        uint32 idealStake,
        uint32 falloff,
        uint32 maxPieceCount,
        uint32 testPrecision
    );

    function setRewardCurve(
        uint32 minInflation,
        uint32 maxInflation,
        uint32 idealStake,
        uint32 falloff,
        uint32 maxPieceCount,
        uint32 testPrecision
    ) external;

    /**
    * @dev Populates the precompile address with dummy bytecode, allowing the precompile to pass related checks.
    * For example, the presence of bytecode allows wallets like Metamask to recognize the precompile as a contract.
    * Must be called by root user.
    */
    function populateBytecode() external;
}
