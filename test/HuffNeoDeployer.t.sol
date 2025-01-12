// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";

import {HuffNeoConfig} from "../src/HuffNeoConfig.sol";
import {HuffNeoDeployer} from "../src/HuffNeoDeployer.sol";
import {INumber} from "./interfaces/INumber.sol";
import {IConstructor} from "./interfaces/IConstructor.sol";
import {IRememberCreator} from "./interfaces/IRememberCreator.sol";

contract HuffNeoDeployerTest is Test {
    INumber private number;
    IConstructor private structor;

    event ArgumentsUpdated(address indexed one, uint256 indexed two);

    function setUp() public {
        number = INumber(HuffNeoDeployer.deploy("test/contracts/Number.huff"));

        vm.recordLogs();
        structor = IConstructor(
            HuffNeoDeployer.deploy_with_args(
                "test/contracts/Constructor.huff",
                bytes.concat(abi.encode(address(0x420)), abi.encode(uint256(0x420)))
            )
        );
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], bytes32(uint256(keccak256("ArgumentsUpdated(address,uint256)"))));
        assertEq(entries[0].topics[1], bytes32(uint256(uint160(address(0x420)))));
        assertEq(entries[0].topics[2], bytes32(uint256(0x420)));
    }

    function testChaining() public {
        vm.recordLogs();
        IConstructor chained = IConstructor(
            HuffNeoDeployer.config().with_args(bytes.concat(abi.encode(address(0x420)), abi.encode(uint256(0x420)))).deploy(
                "test/contracts/Constructor.huff"
            )
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], bytes32(uint256(keccak256("ArgumentsUpdated(address,uint256)"))));
        assertEq(entries[0].topics[1], bytes32(uint256(uint160(address(0x420)))));
        assertEq(entries[0].topics[2], bytes32(uint256(0x420)));

        assertEq(address(0x420), chained.getArgOne());
        assertEq(uint256(0x420), chained.getArgTwo());
    }

    function testChaining_Create2() public {
        vm.recordLogs();
        IConstructor chained = IConstructor(
            HuffNeoDeployer.config_with_create_2(1).with_args(bytes.concat(abi.encode(address(0x420)), abi.encode(uint256(0x420)))).deploy(
                "test/contracts/Constructor.huff"
            )
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], bytes32(uint256(keccak256("ArgumentsUpdated(address,uint256)"))));
        assertEq(entries[0].topics[1], bytes32(uint256(uint160(address(0x420)))));
        assertEq(entries[0].topics[2], bytes32(uint256(0x420)));

        assertEq(address(0x420), chained.getArgOne());
        assertEq(uint256(0x420), chained.getArgTwo());
    }

    function testArgOne() public {
        assertEq(address(0x420), structor.getArgOne());
    }

    function testArgTwo() public {
        assertEq(uint256(0x420), structor.getArgTwo());
    }

    function testBytecode() public view {
        bytes memory b = bytes(hex"5f3560e01c80633fb5c1cb1461001b578063f2c9ecd814610021575b6004355f555b5f545f5260205ff3");
        assertEq(getCode(address(number)), b);
    }

    function testWithValueDeployment() public {
        uint256 value = 1 ether;
        HuffNeoDeployer.config().with_value(value).deploy{value: value}("test/contracts/ConstructorNeedsValue.huff");
    }

    function testWithValueDeployment_Create2() public {
        uint256 value = 1 ether;
        HuffNeoDeployer.config_with_create_2(1).with_value(value).deploy{value: value}("test/contracts/ConstructorNeedsValue.huff");
    }

    function testConstantOverride() public {
        // Test address constant
        address a = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
        address deployed = HuffNeoDeployer.config().with_addr_constant("a", a).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed), hex"73DeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF610420");

        // Test uint constant
        address deployed_2 = HuffNeoDeployer.config().with_uint_constant("a", 32).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed_2), hex"6020610420");

        // Test bytes32 constant
        address deployed_3 = HuffNeoDeployer.config().with_bytes32_constant("a", bytes32(hex"01")).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed_3), hex"7f0100000000000000000000000000000000000000000000000000000000000000610420");

        // Keep default "a" value and assign "b", which is unassigned in "ConstOverride.huff"
        address deployed_4 = HuffNeoDeployer.config().with_constant("b", "0x420").deploy("test/contracts/ConstOverride.huff");
        assertEq(getCode(deployed_4), hex"6001610420");
    }

    function testConstantOverride_Create2() public {
        // Test address constant
        address a = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
        address deployed = HuffNeoDeployer.config_with_create_2(1).with_addr_constant("a", a).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed), hex"73DeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF610420");

        // Test uint constant
        address deployed_2 = HuffNeoDeployer.config_with_create_2(2).with_uint_constant("a", 32).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed_2), hex"6020610420");

        // Test bytes32 constant
        address deployed_3 = HuffNeoDeployer
            .config_with_create_2(3)
            .with_bytes32_constant("a", bytes32(hex"01"))
            .with_constant("b", "0x420")
            .deploy("test/contracts/ConstOverride.huff");
        assertEq(getCode(deployed_3), hex"7f0100000000000000000000000000000000000000000000000000000000000000610420");

        // Keep default "a" value and assign "b", which is unassigned in "ConstOverride.huff"
        address deployed_4 = HuffNeoDeployer.config_with_create_2(4).with_constant("b", "0x420").deploy(
            "test/contracts/ConstOverride.huff"
        );
        assertEq(getCode(deployed_4), hex"6001610420");
    }

    function getCode(address who) internal view returns (bytes memory o_code) {
        /// @solidity memory-safe-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(who)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(who, add(o_code, 0x20), 0, size)
        }
    }

    function testSet(uint256 num) public {
        number.setNumber(num);
        assertEq(num, number.getNumber());
    }

    function testConstructorDefaultCaller() public {
        HuffNeoConfig config = HuffNeoDeployer.config();
        IRememberCreator rememberer = IRememberCreator(config.deploy("test/contracts/RememberCreator.huff"));
        assertEq(rememberer.CREATOR(), address(config));
    }

    function runTestConstructorCaller(address deployer) public {
        IRememberCreator rememberer = IRememberCreator(
            HuffNeoDeployer.config().with_deployer(deployer).deploy("test/contracts/RememberCreator.huff")
        );
        assertEq(rememberer.CREATOR(), deployer);
    }

    // @dev fuzzed test too slow, random examples and address(0) chosen
    function testConstructorCaller() public {
        runTestConstructorCaller(address(uint160(uint256(keccak256("random addr 1")))));
        runTestConstructorCaller(address(uint160(uint256(keccak256("random addr 2")))));
        runTestConstructorCaller(address(0));
        runTestConstructorCaller(address(uint160(0x1000)));
    }

    /// @dev test that compilation is different with new evm versions
    function testSettingEVMVersion() public {
        /// expected bytecode for EVM version "paris"
        bytes memory expectedParis = hex"6000"; // PUSH1 0x00
        HuffNeoConfig parisConfig = HuffNeoDeployer.config().with_evm_version("paris");
        assertEq(parisConfig.get_evm_version(), "paris");

        address withParis = parisConfig.deploy("test/contracts/EVMVersionCheck.huff");
        bytes memory parisBytecode = withParis.code;
        assertEq(parisBytecode, expectedParis);

        /// expected bytecode for EVM version "shanghai"
        bytes memory expectedShanghai = hex"5f"; // PUSH0
        HuffNeoConfig shanghaiConfig = HuffNeoDeployer.config().with_evm_version("shanghai");
        assertEq(shanghaiConfig.get_evm_version(), "shanghai");

        address withShanghai = shanghaiConfig.deploy("test/contracts/EVMVersionCheck.huff");
        bytes memory shanghaiBytecode = withShanghai.code;
        assertEq(shanghaiBytecode, expectedShanghai);

        /// Default should be cancun (latest) which return the same as "shanghai"
        HuffNeoConfig defaultConfig = HuffNeoDeployer.config();
        assertEq(defaultConfig.get_evm_version(), "cancun");

        address withDefault = defaultConfig.deploy("test/contracts/EVMVersionCheck.huff");
        bytes memory defaultBytecode = withDefault.code;
        assertEq(defaultBytecode, expectedShanghai);
    }

    /// @dev test that the deployment fails when the compiler returns an error
    function testEmpty() public {
        HuffNeoConfig config = HuffNeoDeployer.config();
        vm.expectRevert();
        config.deploy("test/contracts/Empty.huff");
    }

    /// @dev test that the deployment fails when the compiler returns an error
    function testEmptyMain() public {
        HuffNeoConfig config = HuffNeoDeployer.config();
        vm.expectRevert();
        config.deploy("test/contracts/EmptyMain.huff");
    }

    /// @dev test that the deployment fails if the file does not exists
    function testFileDoesNotExists() public {
        HuffNeoConfig config = HuffNeoDeployer.config();
        vm.expectRevert();
        config.deploy("DOES_NOT_EXISTS");
    }
}
