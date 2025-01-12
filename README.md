<div align="center">

[![CI](https://github.com/cakevm/foundry-huff-neo/actions/workflows/ci.yaml/badge.svg)](https://github.com/cakevm/foundry-huff-neo/actions/workflows/ci.yaml) [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Telegram Chat][tg-badge]][tg-url] 

[tg-badge]: https://img.shields.io/badge/telegram-huff_neo-2CA5E0?style=plastic&logo=telegram
[tg-url]: https://t.me/huff_neo

</div>

# Foundry Huff Neo
A [foundry](https://github.com/foundry-rs/foundry) library for working with Huff contracts using [huff-neo](https://github.com/cakevm/huff-neo). Take a look at the [project template](https://github.com/cakevm/huff-neo-project-template) to start your own project.


## Installing
First, install the [huff neo compiler](https://github.com/cakevm/huff-neo) (command `hnc`) by running (you find in the compiler repository for more options):
```
curl -L https://raw.githubusercontent.com/cakevm/huff-neo/main/hnc-up/install | bash
```

Then, install this library with [forge](https://github.com/foundry-rs/foundry):
```
forge install cakevm/foundry-huff-neo
```


## Usage
The HuffNeoDeployer is a Solidity library that takes a filename and deploys the corresponding Huff contract, returning the address that the bytecode was deployed to. To use it, simply import it into your file by doing:

```solidity
import {HuffNeoDeployer} from "foundry-huff-neo/HuffNeoDeployer.sol";
```

To compile contracts, you can use `HuffNeoDeployer.deploy(string fileName)`, which takes in a single string representing the filepath. Due to the limits of Foundry/EVM this path should start from the root of your project. When running `forge` make sure that you are in the root directory of your project.

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import {HuffNeoDeployer} from "foundry-huff-neo/HuffNeoDeployer";

interface Number {
  function setNumber(uint256) external;
  function getNumber() external returns (uint256);
}

contract HuffNeoDeployerExample {
  function deploy() public {
    // Deploy a new instance of test/contracts/Number.huff
    address addr = HuffNeoDeployer.deploy("test/contracts/Number.huff");

    // To call a function on the deployed contract, create an interface and wrap the address like so
    Number number = Number(addr);
  }
}
```

To deploy a Huff contract with constructor arguments, you can _chain_ commands onto the HuffNeoDeployer.

For example, to deploy the contract [`src/test/contracts/Constructor.huff`](test/contracts/Constructor.huff) with arguments `(uint256(0x420), uint256(0x420))`, you are encouraged to follow the logic defined in the `deploy` function of the `HuffNeoDeployerArguments` contract below.

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import {HuffNeoDeployer} from "foundry-huff-neo/HuffNeoDeployer";

interface Constructor {
  function getArgOne() external returns (address);
  function getArgTwo() external returns (uint256);
}

contract HuffNeoDeployerArguments {
  function deploy() public {
    // Deploy the contract with arguments
    address addr = HuffNeoDeployer
      .config()
      .with_args(bytes.concat(abi.encode(uint256(0x420)), abi.encode(uint256(0x420))))
      .deploy("test/contracts/Constructor.huff");

    // To call a function on the deployed contract, create an interface and wrap the address
    Constructor construct = Constructor(addr);

    // Validate we deployed the Constructor with the correct arguments
    assert(construct.getArgOne() == address(0x420));
    assert(construct.getArgTwo() == uint256(0x420));
  }

  function depreciated_deploy() public {
    address addr = HuffNeoDeployer.deploy_with_args(
      "test/contracts/Constructor.huff",
      bytes.concat(abi.encode(uint256(0x420)), abi.encode(uint256(0x420)))
    );

    // ...
  }
}
```

## Acknowledgements
Many thanks to the [foundry-huff](https://github.com/huff-language/foundry-huff) contributors and to the authors who maintained it for such a long period! 

## License
This project is licensed under the [Apache 2.0 license](./LICENSE).