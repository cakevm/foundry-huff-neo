import os.path
import re

PATH = os.path.dirname(os.path.abspath(__file__))

# Cheatcodes of these sections only work in scripts
SKIPPED_SECTIONS = {"Scripting"}

# The overload that keeps the plain name of an overloaded cheatcode, the one Solidity tests use most.
# Other overloads get their parameter types as a suffix, so a new overload in forge-std never changes
# what a plain name means.
DEFAULT_OVERLOADS = {
    "prank": "prank(address)",
    "startPrank": "startPrank(address)",
    "expectRevert": "expectRevert()",
    "expectPartialRevert": "expectPartialRevert(bytes4)",
    "expectEmit": "expectEmit()",
    "expectCall": "expectCall(address,bytes)",
    "mockCall": "mockCall(address,bytes,bytes)",
    "mockCallRevert": "mockCallRevert(address,bytes,bytes)",
    "sign": "sign(uint256,bytes32)",
    "signCompact": "signCompact(uint256,bytes32)",
    "assertTrue": "assertTrue(bool)",
    "assertFalse": "assertFalse(bool)",
    "createSelectFork": "createSelectFork(string)",
    "envUint": "envUint(string)",
    "parseJson": "parseJson(string)",
    "parseToml": "parseToml(string)",
    "skip": "skip(bool)",
}

template_static = """
{docs}
/// Consumes {commentArguments} from the stack{returnComment}: vm.{signature}
/// {memoryComment}
#define macro {macroName}(memoryOffset) = takes({takes}) returns({returnCount}) {
{normalize}    __RIGHTPAD(__FUNC_SIG('{signature}'))
    CALL_VM({argumentCount}, {returnLength}, <memoryOffset>){pushReturns}
}
"""

template_variable = """
{docs}
/// Consumes `elements` ABI-encoded words of {commentArguments} from the stack{returnComment}: vm.{signature}
/// Overwrites the calldata and the return data in memory from memoryOffset.
#define macro {macroName}(elements, memoryOffset) = takes(0) returns({returnCount}) {
    __RIGHTPAD(__FUNC_SIG('{signature}'))
    CALL_VM(<elements>, {returnLength}, <memoryOffset>){pushReturns}
}
"""

STATIC_TYPE = re.compile(r"^(u?int\d*|address|bool|bytes([1-9]|[12]\d|3[0-2]))$")
ELEMENTARY_TYPE = re.compile(r"^(u?int\d*|address|bool|bytes\d*|string)(\[\d*\])*$")
SHORT_BYTES = re.compile(r"^bytes([1-9]|[12]\d|3[01])$")


def canonical(solidity_type):
    """The type as it appears in a function signature"""
    return re.sub(r"\b(u?int)\b(?!\d)", r"\g<1>256", solidity_type)


def parameter_types(parameters, enums):
    types = []
    for parameter in [p.strip() for p in parameters.split(",") if p.strip()]:
        solidity_type = re.sub(r"\b(calldata|memory|storage)\b", "", parameter).split()[0]
        types.append("uint8" if solidity_type in enums else canonical(solidity_type))
    return types


def snake_case(name):
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name).upper()


def type_suffix(types):
    return "_".join(t.replace("[]", "_ARRAY").replace("[", "_").replace("]", "").upper() for t in types)


def parse_cheatcodes(source):
    """Yields (name, input types, output types, doc lines) of every cheatcode outside the skipped
    sections whose inputs are ABI types. Outputs may be structs, which are returned as raw ABI data."""
    enums = set(re.findall(r"\benum\s+(\w+)", source))
    section = None
    docs = []
    for line in source.splitlines():
        stripped = line.strip()
        header = re.match(r"// ======== (\w+) ========", stripped)
        if header:
            section = header.group(1)
            docs = []
        elif stripped.startswith("///"):
            docs.append(stripped)
        elif stripped.startswith("function "):
            function = re.match(r"function\s+(\w+)\s*\(([^)]*)\)[^;]*?(?:returns\s*\(([^)]*)\))?\s*;", stripped)
            if function and section not in SKIPPED_SECTIONS:
                inputs = parameter_types(function.group(2), enums)
                outputs = parameter_types(function.group(3) or "", enums)
                if all(ELEMENTARY_TYPE.match(t) for t in inputs):
                    yield function.group(1), inputs, outputs, docs
            docs = []
        elif stripped and not stripped.startswith("//"):
            docs = []


def macro_names(cheatcodes):
    """`VM_` plus the name, with the parameter types as a suffix on overloads other than the default"""
    overloads = {}
    for name, inputs, _, _ in cheatcodes:
        overloads.setdefault(name, []).append(f"{name}({','.join(inputs)})")
    for name, signature in DEFAULT_OVERLOADS.items():
        assert signature in overloads.get(name, []), f"default overload {signature} is not a cheatcode"
    names = []
    for name, inputs, _, _ in cheatcodes:
        signature = f"{name}({','.join(inputs)})"
        plain = len(overloads[name]) == 1 or DEFAULT_OVERLOADS.get(name) == signature
        names.append("VM_" + snake_case(name) + ("" if plain else "_" + type_suffix(inputs)))
    # A suffixed name can match another cheatcode's plain name; a default overload then resolves it
    assert len(names) == len(set(names)), "macro names must be unique"
    return names


def normalize_bytes_arguments(inputs):
    """Code that left-aligns `bytesN` arguments pushed right-aligned, as `__FUNC_SIG` pushes a selector.
    A left-aligned value is either zero or at least 2^(256 - 8N), so it is never shifted."""
    lines = []
    for position, solidity_type in enumerate(inputs):
        short = SHORT_BYTES.match(solidity_type)
        if not short:
            continue
        bits = 8 * int(short.group(1))
        shift = f"dup1 0x{1 << bits:x} gt 0x{256 - bits:x} mul shl"
        code = shift if position == 0 else f"swap{position} {shift} swap{position}"
        lines.append(f"    {code} // left-align {solidity_type}\n")
    return "".join(lines)


def main():
    with open(os.path.join(PATH, "../lib/forge-std/src/Vm.sol"), "r") as file:
        source = file.read()

    cheatcodes = list(parse_cheatcodes(source))

    output = ""
    output += "//\n"
    output += "// Automatically generated by scripts/build_vm_macros.py\n"
    output += "//\n\n"
    output += '#include "vm_call.huff"\n\n'

    for macro_name, (name, inputs, outputs, docs) in zip(macro_names(cheatcodes), cheatcodes):
        signature = f"{name}({','.join(inputs)})"
        static_inputs = all(STATIC_TYPE.match(t) for t in inputs)
        static_outputs = all(STATIC_TYPE.match(t) for t in outputs)

        if not outputs:
            return_comment, return_count, return_length, push_returns = "", 0, "0x00", ""
        elif static_outputs:
            return_comment = f" and pushes {', '.join(outputs)}"
            return_count = len(outputs)
            return_length = hex(32 * len(outputs))
            # The first return value ends up on top of the stack
            push_returns = "".join(
                f"\n    <memoryOffset> 0x{32 * i:x} add mload" if i else "\n    <memoryOffset> mload" for i in reversed(range(len(outputs)))
            )
        else:
            return_comment = f", writes the ABI-encoded {', '.join(outputs)} to memoryOffset and pushes its size"
            return_count = 1
            return_length = "0x00"
            push_returns = "\n    COPY_VM_RETURN_DATA(<memoryOffset>)"

        template = template_static if static_inputs else template_variable
        if static_outputs:
            memory_comment = f"Overwrites {hex(max(4 + 32 * len(inputs), 32 * len(outputs)))} bytes of memory from memoryOffset."
        else:
            memory_comment = "Overwrites the calldata and the return data in memory from memoryOffset."
        output += (
            template.replace("{docs}", "\n".join(docs))
            .replace("{commentArguments}", ", ".join(inputs) if inputs else "nothing")
            .replace("{returnComment}", return_comment)
            .replace("{signature}", signature)
            .replace("{macroName}", macro_name)
            .replace("{memoryComment}", memory_comment)
            .replace("{takes}", str(len(inputs)))
            .replace("{normalize}", normalize_bytes_arguments(inputs) if static_inputs else "")
            .replace("{argumentCount}", hex(len(inputs)))
            .replace("{returnCount}", str(return_count))
            .replace("{returnLength}", return_length)
            .replace("{pushReturns}", push_returns)
            .strip()
            + "\n\n"
        )

    with open(os.path.join(PATH, "../src/vm.huff"), "w") as file:
        file.write(output.rstrip() + "\n")


if __name__ == "__main__":
    main()
