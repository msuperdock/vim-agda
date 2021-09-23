# vim-agda

A neovim plugin for Agda:

- Asynchronous type-checking, using Agda's `--interaction-json` interface.
- Simplified syntax highlighting, without relying on Agda's syntax data.
- Deferred starting of the agda executable until requested.

The syntax highlighting uses the following basic approach:

- Identifiers with no letters are treated as operators.
- Identifiers beginning with a capital letter are treated as types.
- All other identifiers are treated as ordinary identifiers.

As a result, we support interaction with the agda executable, without
sacrificing the ability to quickly open and view syntax-highlighted Agda code.

Supported Agda versions: `>= 2.6.2 && < 2.6.3`.

## Functions

The following functions are currently supported:

| function | description |
| --- | --- |
| `agda#load()` | Load or reload Agda. |
| `agda#abort()` | Abort the current Agda command. |
| `agda#next()` | Move cursor to next hole. |
| `agda#previous()` | Move cursor to previous hole. |
| `agda#give()` | Give expression for hole at cursor. |
| `agda#refine()` | Refine expression for hole at cursor. |
| `agda#environment()` | Display environment for hole at cursor. |
| `agda#unused()` | Check the current file for unused code. |

The `agda#unused()` function requires the `agda-unused` executable (version
`>= 1.0.0`) to be installed on your system; see
[here](https://github.com/msuperdock/agda-unused).

