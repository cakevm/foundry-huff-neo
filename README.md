<div align="center">

[![CI](https://github.com/cakevm/foundry-huff-neo/actions/workflows/ci.yaml/badge.svg)](https://github.com/cakevm/foundry-huff-neo/actions/workflows/ci.yaml) [![Telegram Chat][tg-badge]][tg-url]

[tg-badge]: https://img.shields.io/badge/telegram-huff_neo-2CA5E0?style=plastic&logo=telegram
[tg-url]: https://t.me/huff_neo

</div>

# Foundry Huff Neo
A [foundry](https://github.com/foundry-rs/foundry) library for working with Huff contracts using [huff-neo](https://github.com/cakevm/huff-neo). Take a look at the [project template](https://github.com/cakevm/huff-neo-project-template) to start your own project.

See the [CHANGELOG](./CHANGELOG.md) for breaking changes and details.

## Installing
First, install the [huff neo compiler](https://github.com/cakevm/huff-neo) (command `hnc`) by running:
```
curl -L https://raw.githubusercontent.com/cakevm/huff-neo/main/hnc-up/install | bash
```

Then, install this library with [forge](https://github.com/foundry-rs/foundry):
```
forge install cakevm/foundry-huff-neo
```

## Usage

Import the library:
```solidity
import {HuffNeoDeployer} from "foundry-huff-neo/HuffNeoDeployer.sol";
```

Deploy a contract:
```solidity
address addr = HuffNeoDeployer.deploy("src/MyContract.huff");
```

Deploy with constructor arguments:
```solidity
address addr = HuffNeoDeployer
    .deploy_with_args("src/MyContract.huff", abi.encode(arg1, arg2));
```

## Cheatcodes in Huff tests

`src/vm.huff` gives Huff tests every [Foundry cheatcode](https://getfoundry.sh/reference/cheatcodes/overview) as a macro, and `src/test.huff` adds assertions and calls on top. Run the tests with `hnc test` from huff-neo 1.7.0 or later:
```huff
#include "foundry-huff-neo/test.huff"

#define test WARP() = {
    0x6553f100 VM_WARP(0x00)          // vm.warp(1700000000)
    0x6553f100 timestamp ASSERT_EQ()  // assertEq(block.timestamp, 1700000000)
}
```

```bash
hnc test/MyContract.t.huff test
```

### Arguments and return values
- Arguments are taken from the stack with the first argument on top, and return values are pushed the same way. Pushing `a` and then `b` makes `b` the first argument, so `a b ASSERT_LT()` checks `b < a`, like `a b lt`.
- A `bytes4` or other short `bytesN` argument can be pushed either way: left-aligned as `__ERROR` pushes it, or right-aligned as `__FUNC_SIG` does.
- Cheatcodes with `string`, `bytes` or array arguments take the ABI-encoded words from the stack, first word on top, and their count, such as `VM_LABEL(0x04, 0x00)` for `label(address,string)`. With such a return value, the ABI-encoded data is left at `memoryOffset` and its size is pushed.

### Names
- Each cheatcode is a macro named `VM_` plus its name in snake case: `VM_WARP` for `vm.warp(uint256)`.
- An overloaded cheatcode keeps the plain name for the overload Solidity tests use most, such as `VM_PRANK` for `prank(address)`, `VM_EXPECT_REVERT` for `expectRevert()` and `VM_SIGN` for `sign(uint256,bytes32)`. The other overloads add their parameter types: `VM_EXPECT_REVERT_BYTES4` for `expectRevert(bytes4)`.
- Script cheatcodes and cheatcodes that take Foundry's structs are not included.

### Memory
- `VM_*` macros build their call at `memoryOffset` and say how much memory they overwrite.
- The `test.huff` helpers use free memory, so they never overwrite memory a test uses.

### Helpers in `test.huff`
- `ASSERT_EQ`, `ASSERT_NOT_EQ`, `ASSERT_LT`, `ASSERT_LE`, `ASSERT_GT`, `ASSERT_GE`, their signed `_INT` versions, `ASSERT_EQ_ADDRESS`, `ASSERT_EQ_BYTES32`, `ASSERT_TRUE` and `ASSERT_FALSE`.
- `CALL_FUNCTION(words)`, `CALL_FUNCTION_WITH_VALUE(words)` and `STATICCALL_FUNCTION(words)` call a contract with a selector and argument words. `LAST_RETURN_WORD` reads the return data, before the next call or assertion replaces it.
- `EXPECT_REVERT_CALL(words)` expects a call to revert with an error and fails the test unless it does.
- `EXPECT_CHEATCODE_ERROR(chunks)` fails the test unless the last call failed with a cheatcode error carrying the given message, such as `vm.addr(0)` failing with "vm.addr: private key cannot be 0".

A failed cheatcode or assertion reverts with its message and stops the test. After `VM_EXPECT_REVERT`, an expected revert makes the call report success, so check the flag with `ASSERT_TRUE`, or use `EXPECT_REVERT_CALL`.

See `test/vm.t.huff` for every helper, and `test/vault.t.huff` for testing a contract with decorators and cheatcodes. `test/foundry/` holds Foundry's own cheatcode tests ported to Huff, which check the macros against Foundry's behaviour. `src/vm.huff` is generated from forge-std's `Vm.sol` by `scripts/build_vm_macros.py`.

## Deployment

Deploy to a network using a Foundry script:
```solidity
import {HuffNeoDeployer} from "foundry-huff-neo/HuffNeoDeployer.sol";
import {Script} from "forge-std/Script.sol";

contract Deploy is Script {
    function run() public returns (address) {
        return HuffNeoDeployer.broadcast("src/MyContract.huff");
    }
}
```

```bash
forge script scripts/Deploy.s.sol --rpc-url <RPC_URL> --broadcast
```

## Acknowledgements
This project is a hard-fork from [foundry-huff](https://github.com/huff-language/foundry-huff). Many thanks to all contributors and to the authors who maintained it for such a long period! Thanks to [Huff-Console](https://github.com/AmadiMichael/Huff-Console) for the inspiration for the logging, and to the [Foundry](https://github.com/foundry-rs/foundry) contributors for [forge-std](https://github.com/foundry-rs/forge-std), whose `Vm.sol` the cheatcode macros are generated from.

## License
This project is licensed under the [Apache 2.0 license](./LICENSE).
