#!/usr/bin/env python3
"""Shared parser for PicoGK MCP tool definitions from C# source files.

Extracts all MCP tools (methods marked with [McpServerTool]) from the
PicoGK.Mcp/Tools/*.cs files and returns structured ToolDef objects.

Used by generate-go-mcp-sdk.py and generate-mbt-mcp-sdk.py.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = REPO_ROOT / "PicoGK.Mcp" / "Tools"


@dataclass
class Param:
    name: str
    cs_type: str
    description: str
    default: str | None  # C# default value, or None if required
    has_default: bool


@dataclass
class ToolDef:
    name: str             # e.g. "CreateSphere"
    snake_name: str       # e.g. "create_sphere"
    description: str
    category: str         # e.g. "Primitives", "Boolean"
    params: list[Param] = field(default_factory=list)

    @property
    def required_params(self) -> list[Param]:
        return [p for p in self.params if not p.has_default]

    @property
    def optional_params(self) -> list[Param]:
        return [p for p in self.params if p.has_default]


# --- C# type -> canonical type info ------------------------------------------

TYPE_MAP = {
    "float":      ("float", "number"),
    "int":        ("int", "number"),
    "bool":       ("bool", "boolean"),
    "string":     ("string", "string"),
    "string?":    ("string?", "string"),
    "string[]":   ("string[]", "array"),
}

# --- Parsing -----------------------------------------------------------------

def _extract_description(text: str) -> str:
    """Extract a string from a C# [Description(...)] attribute, handling
    multi-line string concatenation with +."""
    # Join all "..." fragments inside the parentheses
    fragments = re.findall(r'"([^"]*)"', text)
    return "".join(fragments).strip()


def _parse_cs_type(raw: str) -> str:
    """Normalize a C# type token to a canonical key."""
    raw = raw.strip()
    # Remove 'in ' prefix (used for `in Vector3` etc, though we don't see it in params)
    if raw.startswith("in "):
        raw = raw[3:]
    # Map common types
    if raw in TYPE_MAP:
        return raw
    # Fallback: just return as-is
    return raw


def _snake_case(name: str) -> str:
    """Convert PascalCase to snake_case."""
    result = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    result = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", result)
    return result.lower()


def _parse_default(raw: str) -> str | None:
    """Parse a C# default value, returning the raw string or None."""
    raw = raw.strip()
    if not raw:
        return None
    # Strip 'f' suffix from floats: 0.5f -> 0.5
    if raw.endswith("f") and raw[:-1].replace(".", "").replace("-", "").isdigit():
        return raw[:-1]
    return raw


def _parse_tool_block(lines: list[str], start_idx: int) -> tuple[str, str, list[Param]]:
    """Parse a single [McpServerTool] block starting at start_idx.
    Returns (ToolDef, next_index_after_method_body)."""
    idx = start_idx

    # Find [Description(...)] - may span multiple lines
    desc_text = ""
    while idx < len(lines):
        line = lines[idx]
        desc_text += line
        idx += 1
        # Check if the Description attribute is complete (ends with ')])
        if ')]' in line and '[Description' in desc_text:
            break
        # Also handle case where Description spans multiple lines with +
        if ')]' in desc_text and 'Description' in desc_text:
            break

    description = _extract_description(desc_text)

    # Find 'public static string MethodName(' line
    method_line = ""
    while idx < len(lines):
        line = lines[idx].strip()
        idx += 1
        if line.startswith("public static string "):
            method_line = line
            break

    # Extract method name
    m = re.match(r'public\s+static\s+string\s+(\w+)\s*\(', method_line)
    if not m:
        raise ValueError(f"Cannot parse method name from: {method_line}")
    method_name = m.group(1)

    # Now collect all parameter lines until the closing ')'
    # The method_line may contain the opening '(' and possibly the first param
    param_text = ""
    # Extract everything after '(' on the method line
    paren_pos = method_line.find("(")
    if paren_pos >= 0:
        param_text = method_line[paren_pos + 1:]

    # Collect remaining lines until we find the closing ')' (not inside brackets)
    depth = 0
    for ch in param_text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1

    while idx < len(lines) and depth >= 0:
        line = lines[idx]
        idx += 1
        # Check for closing paren at the right depth
        for ch in line:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth < 0:
                    break
        param_text += " " + line
        if depth < 0:
            break

    # Clean up: remove the final ')' and anything after '{'
    brace_pos = param_text.find("{")
    if brace_pos >= 0:
        param_text = param_text[:brace_pos]
    # Remove trailing ')'
    param_text = param_text.rstrip().rstrip(")")

    # Now parse parameters
    params: list[Param] = []

    # Split by comma, but be careful about commas inside [Description("...")]
    # Strategy: parse character by character, tracking string and bracket state.
    # We need to distinguish [] (type array suffix, e.g. string[]) from
    # [Description("...")] (attribute). The key heuristic: [] immediately
    # following a word character is a type suffix, not an attribute.
    parts: list[str] = []
    current = ""
    in_string = False
    in_attr = 0  # bracket depth for [...]
    prev_ch = ""
    for ch in param_text:
        if ch == '"' and (not current.endswith("\\")):
            in_string = not in_string
            current += ch
        elif ch == '[' and not in_string:
            # Check if this is a type suffix [] (preceded by a word char)
            # vs an attribute [Description(...)]
            if prev_ch.isalnum() or prev_ch == ']':
                # This is a type suffix like string[] — don't treat as attribute
                current += ch
            else:
                in_attr += 1
                current += ch
        elif ch == ']' and not in_string:
            if in_attr > 0:
                in_attr -= 1
            current += ch
        elif ch == ',' and not in_string and in_attr == 0:
            parts.append(current.strip())
            current = ""
        else:
            current += ch
        prev_ch = ch
    if current.strip():
        parts.append(current.strip())

    for part in parts:
        part = part.strip()
        if not part:
            continue
        # Skip PicoGkSession session
        if "PicoGkSession" in part:
            continue

        # Extract description from [Description("...")]
        desc_match = re.search(r'\[Description\(("[^"]*"(?:\s*\+\s*"[^"]*")*)\)\]', part)
        if desc_match:
            param_desc = _extract_description(desc_match.group(0))
            # Remove the description attribute from part
            part_clean = part[:desc_match.start()] + part[desc_match.end():]
        else:
            param_desc = ""
            part_clean = part

        # Remove any remaining attribute brackets, but NOT type-suffix [] (empty brackets)
        part_clean = re.sub(r'\[[^\]]+\]', '', part_clean).strip()

        # Parse: type name [= default]
        # Handle types like: float, int, bool, string, string?, string[]
        m = re.match(r'(\w+(?:\[\])?(?:\?)?)\s+(\w+)\s*(?:=\s*(.+))?', part_clean)
        if not m:
            continue

        cs_type = m.group(1)
        param_name = m.group(2)
        default_raw = m.group(3)

        has_default = default_raw is not None
        default_val = _parse_default(default_raw) if has_default else None

        params.append(Param(
            name=param_name,
            cs_type=cs_type,
            description=param_desc,
            default=default_val,
            has_default=has_default,
        ))

    # Determine category from filename
    return method_name, description, params


def parse_mcp_tools() -> list[ToolDef]:
    """Parse all MCP tools from the PicoGK.Mcp/Tools/*.cs files."""
    tools: list[ToolDef] = []

    # Category mapping from filename
    category_map = {
        "SessionTools": "Session",
        "PrimitiveTools": "Primitives",
        "BooleanTools": "Booleans",
        "TransformTools": "Transforms",
        "LatticeTools": "Lattice",
        "MeshTools": "Mesh",
        "QueryTools": "Query",
        "IoTools": "IO",
        "RenderTools": "Render",
    }

    for cs_file in sorted(TOOLS_DIR.glob("*.cs")):
        category = category_map.get(cs_file.stem, "Other")
        lines = cs_file.read_text()

        # Find all [McpServerTool] blocks
        # We need to find the attribute, then the description, then the method
        line_list = lines.split("\n")
        i = 0
        while i < len(line_list):
            if "[McpServerTool]" in line_list[i] and "McpServerToolType" not in line_list[i]:
                try:
                    method_name, description, params = _parse_tool_block(line_list, i)
                    tool = ToolDef(
                        name=method_name,
                        snake_name=_snake_case(method_name),
                        description=description,
                        category=category,
                        params=params,
                    )
                    tools.append(tool)
                except Exception:
                    pass  # Skip unparseable blocks
                # Advance past this block — find next [McpServerTool] or end
                # Simple approach: skip to next occurrence
                i += 1
            else:
                i += 1

    return tools


if __name__ == "__main__":
    tools = parse_mcp_tools()
    print(f"Found {len(tools)} tools:\n")
    for t in tools:
        req = [p.name for p in t.required_params]
        opt = [p.name for p in t.optional_params]
        print(f"  {t.snake_name} ({t.category})")
        print(f"    desc: {t.description[:80]}...")
        if req:
            print(f"    required: {req}")
        if opt:
            print(f"    optional: {opt}")
        print()