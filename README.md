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
This project is a hard-fork from [foundry-huff](https://github.com/huff-language/foundry-huff). Many thanks to all contributors and to the authors who maintained it for such a long period! Thanks to [Huff-Console](https://github.com/AmadiMichael/Huff-Console) for the inspiration for the logging.

## License
This project is licensed under the [Apache 2.0 license](./LICENSE).
