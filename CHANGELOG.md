<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# Foundry Huff Neo changelog

## [Unreleased]
- Add every Foundry cheatcode as a macro for Huff tests in `src/vm.huff`, generated from forge-std's `Vm.sol`.
  - Example: `0x6553f100 VM_WARP(0x00)` for `vm.warp(1700000000)`
  - Requires huff-neo 1.7.0 or later for `hnc test`.
- Add assertions and call helpers in `src/test.huff`, such as `ASSERT_EQ`, `CALL_FUNCTION` and `EXPECT_REVERT_CALL`.
  - See `test/vm.t.huff` and `test/vault.t.huff` for examples.
- Port Foundry's cheatcode tests to Huff in `test/foundry/` to check the macros against Foundry's behaviour.
- Run the Huff tests in `test/*.t.huff` and `test/foundry/*.t.huff` in CI with `make test-huff`.
- Port Foundry's fork tests to `test/foundry/fork/`, run with `make test-huff-fork` against the RPC URL in `MAINNET_HTTP`.
  - `foundry.toml` maps `MAINNET_HTTP` to the `mainnet` RPC alias.

## [1.1.0] - 2026-01-02
- **Breaking**: Refactored `HuffNeoConfig` from a contract to a library with `HuffConfig` struct
  - No more config contract deployed alongside your Huff contract
  - Default deployer is now `msg.sender` instead of the config contract address
- **Breaking**: `get_config_with_create_2(salt)` replaced by `get_create_2_address(salt, file)`
- Default EVM version changed from `cancun` to `osaka`
- Updated to Solidity 0.8.33

## [1.0.1] - 2025-01-29
- Add macros for `console.log` functionalities for Huff contracts.
  - See `test/console.t.huff` for usage examples.

## [1.0.0] - 2025-01-12
- __Breaking__: Rename `HuffDeployer` to `HuffDeployerNeo` and `HuffConfig` to `HuffNeoConfig`
  - Reasoning for this change:
    - Make it clear that this is the Huff Neo Compiler version and has a different API
- __Breaking__: Remove `with_code` option from `HuffDeployer`
    - Generating on the fly code has multiple issues:
        - Can cause include paths to be incorrect
        - Hides the actual code being compiled in the contract
        - Can result in incorrect source without the user knowing
        - Hides errors that would be caught by the eye of the user with syntax highlighting
- __Breaking__: Path for `deploy(filepath)` is passed to the compiler without addition. Before the file path was prefixed with `src` and appended the `.huff`suffix.
  - Reasoning for this change:
    - For the user, is more obvious that the path is a file path
    - Allows to keep the file e.g. in `test` without "hacky" workarounds
- Remove stringutils dependency (no longer needed because code is not generated on the fly)
- Update Foundry to the latest version
- Check stderr for errors after compilation
- Deploy fails if:
  - The compiler returns an error and reports the reason in `HuffNeoCompilerError`
  - The compiler only returns creation bytecode