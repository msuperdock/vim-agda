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

Supported Agda versions: `>= 2.6.1 && < 2.6.2`.

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

## Alternatives

This plugin draws on ideas & code from each of the following plugins. Here's a
comparison:

[derekelkins/agda-vim](https://github.com/derekelkins/agda-vim)

- Supports Agda 2.6.1.
- Doesn't (yet) support asynchronous type-checking.
- Provides syntax highlighting, which is updated by Agda's syntax data.
- On opening a file, the agda executable is started, and the file is loaded.
- Supports most (all?) of the commands supported by the official emacs mode.

[pedrominicz/magda](https://github.com/pedrominicz/magda)

- Doesn't (yet) support Agda 2.6.1.
- Supports asynchronous type-checking.
- Doesn't provide syntax highlighting.
- On opening a file, the agda executable is started, but the file is not loaded.
- Only supports a few commands (load, compute).

