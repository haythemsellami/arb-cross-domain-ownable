// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AddressAliasHelper} from "arbitrum-nitro-contracts/libraries/AddressAliasHelper.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

/// @title CrossDomainOwnable
/// @notice This contract extends the OpenZeppelin `Ownable` contract for Arbitrum L2 contracts to be owned
///         by contracts on either L1 or L2. Note that this contract is meant to be used with
///         systems that use aliased transactions, it will not work when EOA send a signed transactions 
///         using ArbitrumSDK.sendL2SignedTx()
abstract contract CrossDomainOwnable is Ownable {
    /// @notice If true, the contract uses the cross domain _checkOwner function override.
    ///         If false it uses the standard Ownable _checkOwner function.
    bool public isLocal = true;

    /// @notice Emits when ownership of the contract is transferred. Includes the
    ///         isLocal field in addition to the standard `Ownable` OwnershipTransferred event.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner      The new owner of the contract.
    /// @param isLocal       Configures the `isLocal` contract variable.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, bool isLocal);

    /// @notice Allows for ownership to be transferred with specifying the locality.
    /// @param _owner   The new owner of the contract.
    /// @param _isLocal Configures the locality of the ownership.
    function transferOwnership(address _owner, bool _isLocal) external onlyOwner {
        require(_owner != address(0), "CrossDomainOwnable: new owner is the zero address");

        address oldOwner = owner();
        _transferOwnership(_owner);
        isLocal = _isLocal;

        emit OwnershipTransferred(oldOwner, _owner, _isLocal);
    }

    /// @notice Overrides the implementation of the `onlyOwner` modifier to check that the aliased
    ///         `msg.sender` is the owner of the contract by comparing with the aliased version of the owner. 
    function _checkOwner() internal view override {
        if (isLocal) {
            require(owner() == msg.sender, "CrossDomainOwnable: caller is not the owner");
        } else {
            require(AddressAliasHelper.applyL1ToL2Alias(owner()) == msg.sender, "CrossDomainOwnable: caller is not the owner");
        }
    }
}