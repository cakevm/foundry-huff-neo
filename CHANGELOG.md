<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# Foundry Huff Neo changelog

## [Unreleased]

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