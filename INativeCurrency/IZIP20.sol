// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {IERC20} from "./IERC20.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

/// @author The Zenchain Team
/// @title ZIP20 interface
/// @dev see https://github.com/zenchain-protocol/ZIPs/tree/main/ZIPs
interface IZIP20 is IERC20, IERC20Permit {
    // Emitted when a new facilitator is added.
    // @param facilitator: The address of the facilitator.
    // @param label: A human-readable identifier for the facilitator.
    // @param capacity: The bucket capacity assigned to the facilitator.
    event FacilitatorAdded(address indexed facilitator, string label, uint256 capacity);

    // Emitted when a facilitator is removed.
    // @param facilitator: The address of the facilitator being removed.
    event FacilitatorRemoved(address indexed facilitator);

    // Emitted when a facilitator's bucket capacity is updated.
    // @param facilitator: The address of the facilitator.
    // @param oldCapacity: The previous bucket capacity.
    // @param newCapacity: The updated bucket capacity.
    event FacilitatorCapacityUpdated(address indexed facilitator, uint256 oldCapacity, uint256 newCapacity);

    // Emitted when a facilitator's bucket level changes due to minting or burning.
    // @param facilitator: The address of the facilitator.
    // @param oldLevel: The previous bucket level.
    // @param newLevel: The updated bucket level.
    event FacilitatorBucketLevelUpdated(address indexed facilitator, uint256 oldLevel, uint256 newLevel);

    /// @dev Adds a new facilitator with a specified bucket capacity.
    /// @param facilitator The address of the facilitator.
    /// @param label A human-readable identifier for the facilitator.
    /// @param capacity The bucket capacity assigned to the facilitator.
    /// Requirements:
    /// - Access Control: This function MUST only be callable by an authorized account (e.g., one with an admin role).
    /// Effects:
    /// - Adds facilitator to the list of active facilitators.
    /// - Sets the facilitator's bucketCapacity to capacity.
    /// - Initializes the facilitator's bucketLevel to zero.
    /// - Emits the FacilitatorAdded event.
    function addFacilitator(address facilitator, string memory label, uint256 capacity) external;

    /// @dev Removes an existing facilitator.
    /// @param facilitator The address of the facilitator being removed.
    /// Requirements:
    /// - Access Control: This function MUST only be callable by an authorized account.
    /// Effects:
    /// - Removes facilitator from the list of active facilitators.
    /// - Emits the FacilitatorRemoved event.
    function removeFacilitator(address facilitator) external;

    /// @dev Updates the bucket capacity of an existing facilitator.
    /// @param facilitator The address of the facilitator.
    /// @param newCapacity The updated bucket capacity.
    /// Requirements:
    /// - Access Control: This function MUST only be callable by an authorized account.
    /// Effects:
    /// - Updates the facilitator's bucketCapacity to newCapacity.
    /// - Emits the FacilitatorCapacityUpdated event.
    function updateFacilitatorCapacity(address facilitator, uint256 newCapacity) external;

    /// @dev Mints tokens to a specified account.
    /// @param to The address to mint the currency to.
    /// @param amount The amount of currency to mint.
    /// @return A boolean value indicating whether the operation succeeded.
    /// Requirements:
    /// - Caller: This function MUST only be callable by an active facilitator.
    /// - Capacity Check: The facilitator's bucketLevel + amount MUST NOT exceed bucketCapacity.
    /// Effects:
    /// - Increases the facilitator's bucketLevel by amount.
    /// - Mints amount tokens to `to`.
    /// - Emits the FacilitatorBucketLevelUpdated event (with the new bucketLevel).
    /// - Emits the standard ERC20 Transfer event with `from` set to the zero address.
    function mint(address to, uint256 amount) external returns (bool);

    /// @dev Burns tokens from the caller's account.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    /// @return A boolean value indicating whether the operation succeeded.
    /// Requirements:
    /// - Caller: This function MUST only be callable by an active facilitator.
    /// - Balance Check: The `from` MUST have at least `amount` tokens.
    /// - Allowance Check: The `from` MUST have approved at least `amount` tokens to be spended by the facilitator.
    /// Effects:
    /// - Decreases the facilitator's bucketLevel by amount.
    /// - Burns amount tokens from `from`.
    /// - Emits the FacilitatorBucketLevelUpdated event (with the new bucketLevel).
    /// - Emits the standard ERC20 Transfer event with `to` set to the zero address.
    function burn(address from, uint256 amount) external returns (bool);

    /// @dev Returns the bucket capacity, bucket level, and label of a facilitator.
    /// @dev Returns (0, 0, "") if the given address is not a facilitator.
    /// @param facilitator The address of the facilitator.
    /// @return capacity The bucket capacity of the facilitator.
    /// @return level The current bucket level of the facilitator.
    /// @return label The human-readable identifier of the facilitator.
    function getFacilitator(address facilitator) external view returns (uint256 capacity, uint256 level, string memory label);

    /// @dev Returns a list of active facilitator addresses.
    /// @return An array of facilitator addresses.
    function getFacilitators() external view returns (address[] memory);
}