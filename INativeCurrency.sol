// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {IZIP20} from "./INativeCurrency/IZIP20.sol";

/** @dev The contract's address. */
address constant NATIVE_CURRENCY_ADDRESS = 0x0000000000000000000000000000000000000804;

/** @dev The contract's instance. */
NativeCurrency constant NATIVE_CURRENCY_CONTRACT = NativeCurrency(NATIVE_CURRENCY_ADDRESS);

interface NativeCurrency is IZIP20 {
    /// @dev Gets the admin address, which can set minter capacity
    /// @return The address of the admin account
    function getAdmin() external returns (address);

    function deposit() external payable;

    function withdraw(uint256 value) external;

    /**
    * @dev Populates the precompile address with dummy bytecode, allowing the precompile to pass related checks.
    * For example, the presence of bytecode allows wallets like Metamask to recognize the precompile as a contract.
    */
    function populateBytecode() external;
}
