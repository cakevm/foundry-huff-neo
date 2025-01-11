<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# Foundry Huff Neo changelog

## [Unreleased]
- __Breaking__: Rename `HuffDeployer` to `HuffDeployerNeo`
- __Breaking__: Rename `HuffConfig` to `HuffNeoConfig`
  - Reasoning for this change:
    - Make it more clear that this is the Neo version of the compiler
    - Make it clear that is addon for Foundry has a different API
- __Breaking__: Remove `with_code` option from `HuffDeployer`
    - Generating on the fly code has multiple issues:
        - Can cause include paths to be incorrect
        - Hides the actual code being compiled in the contract
        - Can result in incorrect source without the user knowing
- __Breaking__: Path for `deploy()` is not prefixed with `src` anymore
- __Breaking__: Path for `deploy()` does not add extension anymore
  - Reasoning for this change:
    - For the user is more obvious that the path is a file path
- Remove stringutils dependency
- Update all dependencies to the latest version
- Validate that file exists before compiling
- Check stderr for errors after compilation
- Check for zero bytecode length after compilation
- Check if more than creation bytecode is returned

- 