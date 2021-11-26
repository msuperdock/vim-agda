# vim-agda

A neovim plugin for Agda, featuring:

- Asynchronous type-checking.
- Interaction with Agda executable (see functions [here](#functions)).
- Unicode character input (e.g. `\to` for `→`).
- Simple & correct syntax highlighting.
- Optional syntax highlighting & folding in interaction buffer via
 [vim-foldout](https://github.com/msuperdock/vim-foldout).
- Optional unused code checking via
 [agda-unused](https://github.com/msuperdock/agda-unused).

Supported Agda versions: `>= 2.6.2 && < 2.6.3`.

## Installation

Use your preferred installation method. For example, with
[vim-plug](https://github.com/junegunn/vim-plug), use:

```
Plug 'msuperdock/vim-agda'
```

Optionally, install the following:

- [vim-foldout](https://github.com/msuperdock/vim-foldout) (Vim plugin, required
  for syntax highlighting & folding in interaction buffer.)
- [agda-unused](https://github.com/msuperdock/agda-unused) (Haskell application,
  required for the `agda#unused()` function.)

## Functions

vim-agda provides the functions in the table below; we also present the
corresponding emacs commands for reference. You can bind a key to a function in
your `init.vim` using, for example:

```
autocmd BufWinEnter *.agda noremap <silent> <buffer> <leader>l :call agda#load()<cr>
```

This binds `<leader>l` to `agda#load()` for all `.agda` files.

| function | emacs | description |
| --- | --- | --- |
| `agda#load()` | `C-c C-l` | Load or reload Agda. |
| `agda#abort()` | `C-c C-x C-a` | Abort the current Agda command. |
| `agda#next()` | `C-c C-f` | Move cursor to next hole. |
| `agda#previous()` | `C-c C-b` | Move cursor to previous hole. |
| `agda#give()` | `C-c C-SPC` | Give expression for hole at cursor. |
| `agda#refine()` | `C-c C-r` | Refine expression for hole at cursor. |
| `agda#context()` | `C-c C-e` | Display context for hole at cursor. |
| `agda#unused()` | n/a | Check the current file for unused code. |

The `agda#unused()` function requires the
[agda-unused](https://github.com/msuperdock/agda-unused) executable (version
`>= 0.3.0`) to be installed.

## Options

vim-agda provides the global options in the table below. You can set an option
in your `init.vim` using, for example:

```
let g:agda_args = ['--local-interfaces']
```

| variable | default | description |
| --- | --- | --- |
| `g:agda_args` | `[]` | Arguments for `agda` executable. |
| `g:agda_unused_args` | `[]` | Arguments for `agda-unused` executable. |
| `g:agda_debug` | `0` | Log interaction output to the messages buffer. |

## vim-foldout

vim-agda provides optional syntax highlighting & folding in the interaction
buffer via [vim-foldout](https://github.com/msuperdock/vim-foldout). For
example, consider the following Agda file:

```
module Test where

postulate

x = ?
```

After calling `agda#load()`, the interaction buffer appears:

```
-- ## Goals

?0
  : _1
_0
  : Sort
_1
  : _0

-- ## Warnings

/data/code/agda-test/Test.agda:3,1-10
Empty postulate block.

```

If [vim-foldout](https://github.com/msuperdock/vim-foldout) is installed &
enabled, then:

- The goals are syntax-highlighted as Agda code.
- The headings are syntax-highlighted as headings.
- The sections can be folded using
 [vim-foldout](https://github.com/msuperdock/vim-foldout) commands.

Otherwise, the interaction buffer is not syntax-highlighted at all.

