// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";

/// @notice Struct representing a constant override for Huff compilation
struct Constant {
    string key;
    string value;
}

/// @notice Configuration struct for Huff deployments
/// @dev Used with HuffNeoConfig library for fluent API
struct HuffConfig {
    /// @notice Constructor arguments to append to bytecode
    bytes args;
    /// @notice Value to deploy the contract with
    uint256 value;
    /// @notice Address that will be the `msg.sender` (op: caller) in the constructor
    address deployer;
    /// @notice Whether to broadcast the deployment tx
    bool should_broadcast;
    /// @notice EVM version to compile with
    string evm_version;
    /// @notice Salt for CREATE2 deployment
    bytes32 create2_salt;
    /// @notice Whether to use CREATE2 for deployment
    bool use_create2;
    /// @notice Number of constant overrides currently set
    uint8 const_count;
    /// @notice Fixed array for constant overrides (max 32)
    Constant[32] const_overrides;
}

/// @title HuffNeoConfig
/// @notice Library for configuring and deploying Huff contracts
/// @dev Provides a fluent API for setting deployment options
library HuffNeoConfig {
    error HuffNeoCompilerError(string message);

    /// @notice Initializes cheat codes in order to use ffi to compile Huff contracts
    Vm internal constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice Sets the arguments to be appended to the bytecode
    function with_args(HuffConfig memory self, bytes memory args_) internal pure returns (HuffConfig memory) {
        self.args = args_;
        return self;
    }

    /// @notice Sets the amount of wei to deploy the contract with
    function with_value(HuffConfig memory self, uint256 value_) internal pure returns (HuffConfig memory) {
        self.value = value_;
        return self;
    }

    /// @notice Sets the caller of the next deployment
    function with_deployer(HuffConfig memory self, address deployer_) internal pure returns (HuffConfig memory) {
        self.deployer = deployer_;
        return self;
    }

    /// @notice Sets the evm version to compile with. Defaults to "cancun"
    function with_evm_version(HuffConfig memory self, string memory _evm_version)
        internal
        pure
        returns (HuffConfig memory)
    {
        self.evm_version = _evm_version;
        return self;
    }

    /// @notice Sets a constant to a bytes memory value in the current compilation environment
    /// @dev The `value` string must contain a valid hex number that is <= 32 bytes
    ///      i.e. "0x01", "0xa57b", "0x0de0b6b3a7640000", etc.
    function with_constant(HuffConfig memory self, string memory key, string memory value_)
        internal
        pure
        returns (HuffConfig memory)
    {
        require(self.const_count < 32, "HuffNeoConfig: max 32 constant overrides");
        self.const_overrides[self.const_count] = Constant(key, value_);
        self.const_count++;
        return self;
    }

    /// @notice Sets a constant to an address value in the current compilation environment
    function with_addr_constant(HuffConfig memory self, string memory key, address value_)
        internal
        pure
        returns (HuffConfig memory)
    {
        return with_constant(self, key, bytes_to_hex_string(abi.encodePacked(value_)));
    }

    /// @notice Sets a constant to a bytes32 value in the current compilation environment
    function with_bytes32_constant(HuffConfig memory self, string memory key, bytes32 value_)
        internal
        pure
        returns (HuffConfig memory)
    {
        return with_constant(self, key, bytes_to_hex_string(abi.encodePacked(value_)));
    }

    /// @notice Sets a constant to a uint256 value in the current compilation environment
    function with_uint_constant(HuffConfig memory self, string memory key, uint256 value_)
        internal
        pure
        returns (HuffConfig memory)
    {
        return with_constant(self, key, bytes_to_hex_string(abi.encodePacked(value_)));
    }

    /// @notice Sets whether to broadcast the deployment
    function set_broadcast(HuffConfig memory self, bool broadcast) internal pure returns (HuffConfig memory) {
        self.should_broadcast = broadcast;
        return self;
    }

    /// @notice Convert bytes to hex string
    function bytes_to_hex_string(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /// @notice Get the evm version string | else return default ("osaka")
    function get_evm_version(HuffConfig memory self) internal pure returns (string memory) {
        bytes memory _evm_version = bytes(self.evm_version);
        if (_evm_version.length == 0) {
            return "osaka";
        }
        return self.evm_version;
    }

    /// @notice Get the creation bytecode of a contract
    function creation_code(HuffConfig memory self, string memory filepath) internal returns (bytes memory bytecode) {
        // Create a list of strings with the commands necessary to compile Huff contracts
        string[] memory cmds = new string[](5);

        // Check if there are any constant overrides
        if (self.const_count > 0) {
            cmds = new string[](6 + self.const_count);
            cmds[5] = "-c";

            Constant memory cur_const;
            for (uint256 i; i < self.const_count; i++) {
                cur_const = self.const_overrides[i];
                cmds[6 + i] = string.concat(cur_const.key, "=", cur_const.value);
            }
        }

        cmds[0] = "hnc";
        cmds[1] = filepath;
        cmds[2] = "-b";
        cmds[3] = "-e";
        cmds[4] = get_evm_version(self);

        /// Call the compiler
        Vm.FfiResult memory f = vm.tryFfi(cmds);

        // Check if the compiler failed
        if (f.exitCode != 0) {
            revert HuffNeoCompilerError(string(f.stderr));
        }

        bytecode = f.stdout;
        require(bytecode.length > 0, "Huff Neo compiler returned empty bytecode.");
        // The contraction creation code 60008060093d393df3 = 9 bytes
        require(bytecode.length > 9, "Huff Neo compiler returned only contract creation code.");
    }

    /// @notice get creation code of a contract plus encoded arguments
    function creation_code_with_args(HuffConfig memory self, string memory file)
        internal
        returns (bytes memory bytecode)
    {
        bytecode = creation_code(self, file);
        return bytes.concat(bytecode, self.args);
    }

    /// @notice Deploy the Contract
    function deploy(HuffConfig memory self, string memory file) internal returns (address) {
        bytes memory concatenated = creation_code_with_args(self, file);

        if (self.should_broadcast) {
            vm.broadcast();
        } else {
            vm.prank(self.deployer);
        }

        address deployedAddress;
        uint256 deployValue = self.value;

        if (self.use_create2) {
            bytes32 salt = self.create2_salt;
            assembly {
                deployedAddress := create2(deployValue, add(concatenated, 0x20), mload(concatenated), salt)
            }
        } else {
            assembly {
                deployedAddress := create(deployValue, add(concatenated, 0x20), mload(concatenated))
            }
        }

        /// @notice check that the deployment was successful
        require(deployedAddress != address(0), "HuffNeoDeployer could not deploy contract");

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
