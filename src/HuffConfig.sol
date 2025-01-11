// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";

contract HuffConfig {
    error HuffNeoCompilerFailed(string message);

    /// @notice Initializes cheat codes in order to use ffi to compile Huff contracts
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice Struct that represents a constant to be passed to the `-c` flag
    struct Constant {
        string key;
        string value;
    }

    /// @notice additional code to append to the source file
    string public code;

    /// @notice arguments to append to the bytecode
    bytes public args;

    /// @notice value to deploy the contract with
    uint256 public value;

    /// @notice address that will be the `msg.sender` (op: caller) in the constructor
    /// @dev set to config address to ensure backwards compatibility
    address public deployer = address(this);

    /// @notice whether to broadcast the deployment tx
    bool public should_broadcast;

    /// @notice supported evm versions
    string public evm_version;

    /// @notice constant overrides for the current compilation environment
    Constant[] public const_overrides;

    /// @notice sets the code to be appended to the source file
    function with_code(string memory code_) public returns (HuffConfig) {
        code = code_;
        return this;
    }

    /// @notice sets the arguments to be appended to the bytecode
    function with_args(bytes memory args_) public returns (HuffConfig) {
        args = args_;
        return this;
    }

    /// @notice sets the amount of wei to deploy the contract with
    function with_value(uint256 value_) public returns (HuffConfig) {
        value = value_;
        return this;
    }

    /// @notice sets the caller of the next deployment
    function with_deployer(address _deployer) public returns (HuffConfig) {
        deployer = _deployer;
        return this;
    }

    /// @notice sets the evm version to compile with
    function with_evm_version(string memory _evm_version) public returns (HuffConfig) {
        evm_version = _evm_version;
        return this;
    }

    /// @notice sets a constant to a bytes memory value in the current compilation environment
    /// @dev The `value` string must contain a valid hex number that is <= 32 bytes
    ///      i.e. "0x01", "0xa57b", "0x0de0b6b3a7640000", etc.
    function with_constant(string memory key, string memory value_) public returns (HuffConfig) {
        const_overrides.push(Constant(key, value_));
        return this;
    }

    /// @notice sets a constant to an address value in the current compilation environment
    function with_addr_constant(string memory key, address value_) public returns (HuffConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets a constant to a bytes32 value in the current compilation environment
    function with_bytes32_constant(string memory key, bytes32 value_) public returns (HuffConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets a constant to a uint256 value in the current compilation environment
    function with_uint_constant(string memory key, uint256 value_) public returns (HuffConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets whether to broadcast the deployment
    function set_broadcast(bool broadcast) public returns (HuffConfig) {
        should_broadcast = broadcast;
        return this;
    }

    function bytesToString(bytes memory data) public pure returns (string memory) {
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

    /// @notice Get the evm version string | else return default ("shanghai")
    function get_evm_version() public view returns (string memory) {
        bytes32 _evm_version = bytes32(bytes(abi.encodePacked(evm_version)));
        if (_evm_version == bytes32(0x0)) {
            return "shanghai";
        }
        return evm_version;
    }

    /// @notice Get the creation bytecode of a contract
    function creation_code(string memory filepath) public payable returns (bytes memory bytecode) {
        string memory full_filepath = string.concat("src/", filepath, ".huff");
        // Check if the file exists (vm.isFile would require permission)
        string[] memory check_cmds = new string[](3);
        check_cmds[0] = "test";
        check_cmds[1] = "-f";
        check_cmds[2] = full_filepath;
        Vm.FfiResult memory check = vm.tryFfi(check_cmds);
        require(check.exitCode == 0, "Huff file does not exist.");

        // Get a random file name
        string[] memory rnd_cmd = new string[](1);
        rnd_cmd[0] = "./lib/foundry-huff-neo/scripts/rand_bytes.sh";
        Vm.FfiResult memory rnd_result = vm.tryFfi(rnd_cmd);
        require(rnd_result.exitCode == 0, "Failed to execute random bytes command.");

        // Check if the random bytes are 16 bytes long
        bytes memory random_bytes = rnd_result.stdout;
        require(random_bytes.length == 16, "Failed to read random bytes.");

        // Build the temp file path
        string memory tmp_filepath = string.concat("src/", bytesToString(random_bytes), ".huff");

        // Paste the code in a new temp file
        string[] memory create_cmds = new string[](3);
        create_cmds[0] = "./lib/foundry-huff-neo/scripts/file_writer.sh";
        create_cmds[1] = string.concat(code, "\n");
        create_cmds[2] = tmp_filepath;
        Vm.FfiResult memory create_result = vm.tryFfi(create_cmds);
        require(create_result.exitCode == 0, "Failed to create temp file.");

        // Append the code from the file to the temp file
        string[] memory append_cmds = new string[](3);
        append_cmds[0] = "./lib/foundry-huff-neo/scripts/read_and_append.sh";
        append_cmds[1] = full_filepath;
        append_cmds[2] = tmp_filepath;
        Vm.FfiResult memory append_result = vm.tryFfi(append_cmds);
        require(append_result.exitCode == 0, "Failed to append Huff file to temp file.");

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
        cmds[1] = tmp_filepath;
        cmds[2] = "-b";
        cmds[3] = "-e";
        cmds[4] = get_evm_version();

        /// Call the compiler
        Vm.FfiResult memory f = vm.tryFfi(cmds);

        // Clean up temp files
        string[] memory cleanup = new string[](2);
        cleanup[0] = "rm";
        cleanup[1] = tmp_filepath;
        vm.ffi(cleanup);

        // Check if the compiler failed
        if (f.exitCode != 0) {
            revert HuffNeoCompilerFailed(string(f.stderr));
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
        require(deployedAddress != address(0), "HuffDeployer could not deploy contract");

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
