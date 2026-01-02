// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {HuffConfig, Constant, HuffNeoConfig} from "./HuffNeoConfig.sol";

/// @title HuffNeoDeployer
/// @notice Library for deploying Huff contracts with various configuration options
/// @dev Provides both simple deployment functions and a fluent API via HuffConfig
library HuffNeoDeployer {
    using HuffNeoConfig for HuffConfig;

    /// @notice Create a new Huff config with default settings
    /// @return A new HuffConfig struct with deployer set to msg.sender
    function config() internal view returns (HuffConfig memory) {
        HuffConfig memory c;
        c.deployer = msg.sender;
        return c;
    }

    /// @notice Create a new Huff config for CREATE2 deployment
    /// @param salt The salt to use for CREATE2 deployment
    /// @return A new HuffConfig struct configured for CREATE2
    function config_with_create_2(uint256 salt) internal view returns (HuffConfig memory) {
        HuffConfig memory c = config();
        c.use_create2 = true;
        c.create2_salt = bytes32(salt);
        return c;
    }

    /// @notice Predict the address of a contract deployed with CREATE2
    /// @param salt The salt to use for CREATE2 deployment
    /// @param file The path to the Huff contract file
    /// @return The predicted address of the deployed contract
    function get_create_2_address(uint256 salt, string memory file) internal returns (address) {
        HuffConfig memory c = config_with_create_2(salt);
        bytes memory bytecode = c.creation_code_with_args(file);
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), bytes32(salt), keccak256(bytecode))))));
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @return The address that the contract was deployed to
    function deploy(string memory fileName) internal returns (address) {
        return config().deploy(fileName);
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @return The address that the contract was deployed to
    function broadcast(string memory fileName) internal returns (address) {
        return config().set_broadcast(true).deploy(fileName);
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @param value - Value to deploy with
    /// @return The address that the contract was deployed to
    function deploy_with_value(string memory fileName, uint256 value) internal returns (address) {
        return config().with_value(value).deploy(fileName);
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @param value - Value to deploy with
    /// @return The address that the contract was deployed to
    function broadcast_with_value(string memory fileName, uint256 value) internal returns (address) {
        return config().set_broadcast(true).with_value(value).deploy(fileName);
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @param args - Constructor Args to append to the bytecode
    /// @return The address that the contract was deployed to
    function deploy_with_args(string memory fileName, bytes memory args) internal returns (address) {
        return config().with_args(args).deploy(fileName);
    }

    /// @notice Compiles a Huff contract and returns the address that the contract was deployed to
    /// @param fileName - The file name of the Huff contract. For example, the file name for "SimpleStore.huff" is "SimpleStore"
    /// @param args - Constructor Args to append to the bytecode
    /// @return The address that the contract was deployed to
    function broadcast_with_args(string memory fileName, bytes memory args) internal returns (address) {
        return config().set_broadcast(true).with_args(args).deploy(fileName);
    }
}
