// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";

import {HuffConfig, Constant, HuffNeoConfig} from "../src/HuffNeoConfig.sol";
import {HuffNeoDeployer} from "../src/HuffNeoDeployer.sol";
import {INumber} from "./interfaces/INumber.sol";
import {IConstructor} from "./interfaces/IConstructor.sol";

contract HuffNeoConfigTest is Test {
    using HuffNeoConfig for HuffConfig;

    function testWithDeployer(address deployer) public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.with_deployer(deployer);
        assertEq(cfg.deployer, deployer);
    }

    function testWithArgs(bytes memory some) public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.with_args(some);
        assertEq(cfg.args, some);
    }

    function testWithValue(uint256 value) public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.with_value(value);
        assertEq(cfg.value, value);
    }

    function testWithConstantOverrides(string memory key, string memory value) public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.with_constant(key, value);
        assertEq(cfg.const_count, 1);
        assertEq(cfg.const_overrides[0].key, key);
        assertEq(cfg.const_overrides[0].value, value);
    }

    function testSetBroadcast(bool broadcast) public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.set_broadcast(broadcast);
        assertEq(cfg.should_broadcast, broadcast);
    }

    function testWithEvmVersion() public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        cfg = cfg.with_evm_version("paris");
        assertEq(cfg.evm_version, "paris");
    }

    function testDefaultDeployer() public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        // msg.sender in library context is the transaction sender
        assertEq(cfg.deployer, msg.sender);
    }

    function testCreate2Config() public {
        HuffConfig memory cfg = HuffNeoDeployer.config_with_create_2(123);
        assertEq(cfg.use_create2, true);
        assertEq(cfg.create2_salt, bytes32(uint256(123)));
    }

    function testMaxConstantOverrides() public {
        HuffConfig memory cfg = HuffNeoDeployer.config();

        // Add 32 constants (max allowed)
        for (uint256 i = 0; i < 32; i++) {
            cfg = cfg.with_constant(string(abi.encodePacked("key", vm.toString(i))), string(abi.encodePacked("0x", vm.toString(i))));
        }

        assertEq(cfg.const_count, 32);
    }

    function testMaxConstantOverridesReverts() public {
        HuffConfig memory cfg = HuffNeoDeployer.config();

        // Add 32 constants (max allowed)
        for (uint256 i = 0; i < 32; i++) {
            cfg = cfg.with_constant(string(abi.encodePacked("key", vm.toString(i))), string(abi.encodePacked("0x", vm.toString(i))));
        }

        // Adding 33rd should revert - use try/catch for internal function
        try this.addConstantHelper(cfg) {
            revert("Should have reverted");
        } catch {}
    }

    // Helper function to test revert in internal library call
    function addConstantHelper(HuffConfig memory cfg) external pure returns (HuffConfig memory) {
        return cfg.with_constant("key32", "0x32");
    }

    function testChaining() public {
        HuffConfig memory cfg = HuffNeoDeployer
            .config()
            .with_deployer(address(0x1234))
            .with_value(1 ether)
            .with_evm_version("shanghai")
            .set_broadcast(true)
            .with_constant("KEY", "0x123");

        assertEq(cfg.deployer, address(0x1234));
        assertEq(cfg.value, 1 ether);
        assertEq(cfg.evm_version, "shanghai");
        assertEq(cfg.should_broadcast, true);
        assertEq(cfg.const_count, 1);
        assertEq(cfg.const_overrides[0].key, "KEY");
        assertEq(cfg.const_overrides[0].value, "0x123");
    }

    function testGetEvmVersionDefault() public {
        HuffConfig memory cfg = HuffNeoDeployer.config();
        assertEq(cfg.get_evm_version(), "osaka");
    }

    function testGetEvmVersionCustom() public {
        HuffConfig memory cfg = HuffNeoDeployer.config().with_evm_version("paris");
        assertEq(cfg.get_evm_version(), "paris");
    }

    function testBytesToHexString() public pure {
        bytes memory data = hex"deadbeef";
        string memory result = HuffNeoConfig.bytes_to_hex_string(data);
        assertEq(result, "0xdeadbeef");
    }

    function testBytesToHexStringAddress() public pure {
        bytes memory data = abi.encodePacked(address(0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF));
        string memory result = HuffNeoConfig.bytes_to_hex_string(data);
        // Function outputs lowercase hex
        assertEq(result, "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef");
    }
}
