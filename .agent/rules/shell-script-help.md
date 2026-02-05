# Shell Script Help Format Guidelines

Every Shell script in this project must follow the standard help section format defined below.

## 1. Help Outline (Mandatory)
The help section must contain exactly these 7 sections in this specific order. Even if a section is empty, the header must be preserved.

1. 用途：
2. 依赖：
3. 注意：
4. 用法：
5. 参数规范：
6. 参数说明：
7. 示例：

## 2. Parameter Specification (参数规范)
The notation in the **用法** (Usage) section must strictly follow these symbols defined in **参数规范**:

| Notation | Example | Meaning |
| :--- | :--- | :--- |
| **No Symbols** | `-a`, `val` | **Mandatory** option or value. |
| **No Symbols** | `val1 val2 -a -b` | Mandatory, order does not matter. |
| **`[]`** | `[-a]`, `[val]` | **Optional** option or value. |
| **`<>`** | `<val>` | **Placeholder** (user must provide specific value). |
| **`%%`** | `%val%` | **Wildcard** (substring match, e.g., `%error%`). |
| **`|`** | `v1|v2|<v3>` | **OR** logic (pick one). |
| **`{}`** | `{-a <val>}` | **Atomic Group**: Option and value must appear together. |
| **`{}`** | `{val1 val2}` | **Sequential Group**: Mandatory values in specific order. |

## 3. Formatting
- Use leading spaces/indentation for alignment as found in the original templates.
- Ensure the `F_HELP` function (or equivalent) outputs exactly this structure.
