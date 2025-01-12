// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";

contract HuffNeoConfig {
    error HuffNeoCompilerError(string message);

    /// @notice Initializes cheat codes in order to use ffi to compile Huff contracts
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice Struct that represents a constant to be passed to the `-c` flag
    struct Constant {
        string key;
        string value;
    }

    /// @notice Arguments to append to the bytecode
    bytes public args;

    /// @notice Value to deploy the contract with
    uint256 public value;

    /// @notice Address that will be the `msg.sender` (op: caller) in the constructor
    /// @dev set to config address to ensure backwards compatibility
    address public deployer = address(this);

    /// @notice Whether to broadcast the deployment tx
    bool public should_broadcast;

    /// @notice EVM version to compile with
    string public evm_version;

    /// @notice Constant overrides for the current compilation environment
    Constant[] public const_overrides;

    /// @notice Sets the arguments to be appended to the bytecode
    function with_args(bytes memory args_) public returns (HuffNeoConfig) {
        args = args_;
        return this;
    }

    /// @notice Sets the amount of wei to deploy the contract with
    function with_value(uint256 value_) public returns (HuffNeoConfig) {
        value = value_;
        return this;
    }

    /// @notice Sets the caller of the next deployment
    function with_deployer(address _deployer) public returns (HuffNeoConfig) {
        deployer = _deployer;
        return this;
    }

    /// @notice Sets the evm version to compile with. Defaults to "cancun"
    function with_evm_version(string memory _evm_version) public returns (HuffNeoConfig) {
        evm_version = _evm_version;
        return this;
    }

    /// @notice Sets a constant to a bytes memory value in the current compilation environment
    /// @dev The `value` string must contain a valid hex number that is <= 32 bytes
    ///      i.e. "0x01", "0xa57b", "0x0de0b6b3a7640000", etc.
    function with_constant(string memory key, string memory value_) public returns (HuffNeoConfig) {
        const_overrides.push(Constant(key, value_));
        return this;
    }

    /// @notice Sets a constant to an address value in the current compilation environment
    function with_addr_constant(string memory key, address value_) public returns (HuffNeoConfig) {
        const_overrides.push(Constant(key, bytes_to_hex_string(abi.encodePacked(value_))));
        return this;
    }

    /// @notice Sets a constant to a bytes32 value in the current compilation environment
    function with_bytes32_constant(string memory key, bytes32 value_) public returns (HuffNeoConfig) {
        const_overrides.push(Constant(key, bytes_to_hex_string(abi.encodePacked(value_))));
        return this;
    }

    /// @notice Sets a constant to a uint256 value in the current compilation environment
    function with_uint_constant(string memory key, uint256 value_) public returns (HuffNeoConfig) {
        const_overrides.push(Constant(key, bytes_to_hex_string(abi.encodePacked(value_))));
        return this;
    }

    /// @notice Sets whether to broadcast the deployment
    function set_broadcast(bool broadcast) public returns (HuffNeoConfig) {
        should_broadcast = broadcast;
        return this;
    }

    /// @notice Convert bytes to hex string
    function bytes_to_hex_string(bytes memory data) public pure returns (string memory) {
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

    /// @notice Get the evm version string | else return default ("cancun")
    function get_evm_version() public view returns (string memory) {
        bytes memory _evm_version = bytes(evm_version);
        if (_evm_version.length == 0) {
            return "cancun";
        }
        return evm_version;
    }

    /// @notice Get the creation bytecode of a contract
    function creation_code(string memory filepath) public payable returns (bytes memory bytecode) {
        // Create a list of strings with the commands necessary to compile Huff contracts
        string[] memory cmds = new string[](5);

        // Check if there are any constant overrides
        if (const_overrides.length > 0) {
            cmds = new string[](6 + const_overrides.length);
            cmds[5] = "-c";

            Constant memory cur_const;
            for (uint256 i; i < const_overrides.length; i++) {
                cur_const = const_overrides[i];
                cmds[6 + i] = string.concat(cur_const.key, "=", cur_const.value);
            }
        }

        cmds[0] = "hnc";
        cmds[1] = filepath;
        cmds[2] = "-b";
        cmds[3] = "-e";
        cmds[4] = get_evm_version();

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
    function creation_code_with_args(string memory file) public payable returns (bytes memory bytecode) {
        bytecode = creation_code(file);
        return bytes.concat(bytecode, args);
    }

    /// @notice Deploy the Contract
    function deploy(string memory file) public payable returns (address) {
        bytes memory concatenated = creation_code_with_args(file);

        if (should_broadcast) {
            vm.broadcast();
        } else {
            vm.prank(deployer);
        }

        address deployedAddress;
        assembly {
            let val := sload(value.slot)
            deployedAddress := create(val, add(concatenated, 0x20), mload(concatenated))
        }

        /// @notice check that the deployment was successful
        require(deployedAddress != address(0), "HuffNeoDeployer could not deploy contract");

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
