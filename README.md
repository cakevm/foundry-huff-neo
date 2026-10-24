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

Deploy Huff contracts from Solidity tests. For tests written in Huff, see [Cheatcodes in Huff tests](#cheatcodes-in-huff-tests).

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

Huff tests can use [Foundry's cheatcodes](https://getfoundry.sh/reference/cheatcodes/overview) as `VM_*` macros, with assertions and call helpers such as `ASSERT_EQ` and `CALL_FUNCTION`. They need `hnc` 1.7.1 or later:
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

- Arguments come from the stack with the first argument on top, so `a b ASSERT_LT()` checks `b < a`, like `a b lt`.
- `VM_*` macros take a `memoryOffset` to build their call in. The common overload of a cheatcode has the plain name, such as `VM_EXPECT_REVERT`, and the others add their parameter types, such as `VM_EXPECT_REVERT_BYTES4`.
- A failed cheatcode or assertion stops the test with its message.

See [`src/test.huff`](./src/test.huff) for the helpers, and [`test/vm.t.huff`](./test/vm.t.huff) and [`test/vault.t.huff`](./test/vault.t.huff) for examples.

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
This project is a hard-fork from [foundry-huff](https://github.com/huff-language/foundry-huff). Many thanks to all contributors and to the authors who maintained it for such a long period! Thanks to [Huff-Console](https://github.com/AmadiMichael/Huff-Console) for the inspiration for the logging. Thanks to the [Foundry](https://github.com/foundry-rs/foundry) contributors: the cheatcode macros are generated from [forge-std](https://github.com/foundry-rs/forge-std)'s `Vm.sol`, and `test/foundry/` ports Foundry's cheatcode tests (MIT OR Apache-2.0).

## License
This project is licensed under the [Apache 2.0 license](./LICENSE).
