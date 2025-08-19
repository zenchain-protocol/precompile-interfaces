pragma solidity ^0.8.0;

/** @dev The contract's address. */
address constant TREASURY_ADDRESS = 0x0000000000000000000000000000000000000806;

/** @dev The contract's instance. */
Treasury constant TREASURY_CONTRACT = Treasury(TREASURY_ADDRESS);

interface Treasury {

    event NewTreasury(address indexed treasury);

    /**
     * @notice Updates the treasury address in the system
     * @dev This function can only be called with root/admin privileges
     * @param new_treasury The address to set as the new treasury
     * @custom:emits NewTreasury event when successfully executed
     */
    function setTreasury(address new_treasury) external;

    /**
     * @notice Retrieves the current treasury address
     * @dev Returns the address of the configured treasury account from the system
     * @return The address of the current treasury, or the zero address if no treasury is set
     */
    function treasury() external view returns (address);

    /**
    * @dev Populates the precompile address with dummy bytecode, allowing the precompile to pass related checks.
    * For example, the presence of bytecode allows wallets like Metamask to recognize the precompile as a contract.
    */
    function populateBytecode() external;
}
