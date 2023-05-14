# Vuffers.nvim

<p align="center">
  <img width="400" src="https://user-images.githubusercontent.com/26042720/233860459-7d4da8f7-7ca7-4900-b274-e426a40e3dfa.png">
</p>

## ❓ What is it

Introducing a new experimental and exciting plugin for buffers! This plugin gives you a vertical overview of all your open buffers. With the added functionality of such as sorting buffers, it allows for easy navigation and organization of your workspace.

⚠️ Disclaimer:
Please keep in mind that this is an early version of the plugin, and there may be some bugs or quirks. However, I'm excited to share this tool with you and I hope you'll find it useful and that it will improve your workflows.

<br>

## 🔋 Motivation

The motivation behind this plugin is to provide a simple and efficient way to manage buffers in Neovim. While there are already some plugins that offer similar functionality, they don't quite meet my needs. I prefer to see my buffers in a vertical list, so that I can easily view all of my files at once.

Plugins like Bufferline are helpful, but they display buffers horizontally, which limits the number of files I can see at any given time. While Telescope has a buffers picker, I prefer a list that is always visible.

Furthermore, I often work with files that have similar names, but are located in different folders. I want to be able to order my buffers in a way that groups these files together, regardless of their location. For example, `foo.ts` and `foo.test.ts` should be next to each other in the list, even if one is in `foo/bar/baz/` and the other is in `tests/`.

With this plugin, I aim to provide a solution that addresses these specific needs, making it easier and more efficient to manage buffers in Neovim.

<br>

## ✨ Features

- Vertical display of open buffers for easy navigation
- Display of file names with duplicates eliminated for better readability
  - For example, `foo/bar/baz.ts` would be displayed simply as `baz` if there are no other files with that name open
- Unique naming of files with duplicates to avoid confusion
  - For example, if both `a/foo/baz.ts` and `b/bar/baz.ts` are open, they will be shown as `foo/baz` and `bar/baz` respectively
- Shortcuts for seamless navigation between buffers
- Sorting of buffers for customizable organization of your workflow

<br>

## 🔍 Demo

Unique names

https://user-images.githubusercontent.com/26042720/233858903-e1186e9b-f795-4de5-9d7d-d6b8ae560de2.mp4

Sort

https://user-images.githubusercontent.com/26042720/233858922-bf42c8f1-e56b-4bc5-a7af-1532826656e2.mp4

Navigation

https://user-images.githubusercontent.com/26042720/233858935-e7a72733-b8aa-4cb2-ab36-9f345b9896a1.mp4

<br>

## ❗ Requirements

- Neovim >= 0.8.0

Older versions may work without a problem but not tested

<br>

### Dependencies

- nvim-tree/nvim-web-devicons

<br>

## ⚙️ Setup

default setup with lazy.nvim

```lua
return {
  "Hajime-Suzuki/vuffers.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("vuffers").setup({
      debug = {
        enabled = true,
        level = "error", -- "error" | "warn" | "info" | "debug" | "trace"
      },
      exclude = {
        -- do not show them on the vuffers list
        filenames = { "term://" },
        filetypes = { "lazygit", "NvimTree", "qf" },
      },
      handlers = {
        -- when deleting a buffer via vuffers list (by default triggered by "d" key)
        on_delete_buffer = function(bufnr)
          vim.api.nvim_command(":bwipeout " .. bufnr)
        end,
      },
      keymaps = {
        use_default = true,
        -- key maps on the vuffers list
        view = {
          open = "<CR>",
          delete = "d",
          pin = "p",
          unpin = "P",
        },
      },
      sort = {
        type = "none", -- "none" | "filename"
        direction = "asc", -- "asc" | "desc"
      },
      view = {
        modified_icon = "󰛿", -- when a buffer is modified, this icon will be shown
        pinned_icon = "󰐾",
        window = {
          width = 35,
          focus_on_open = false,
        },
      },
    })
  end,
}
```

<br>

## 🔫 Usage

| function                            | param                                                         | description                                                                                                                |
| ----------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `go_to_buffer_by_count`             | `{direction: 'next' \| 'prev', count?: integer }`             | open the next or previous buffer in the vuffers list. works with v count                                                   |
| `go_to_buffer_by_line`              | `line_number?: integer`                                       | open the buffer on the specified line. works with line number                                                              |
| `sort`                              | `{type: 'none' \| 'filename', direction: 'asc' \| 'desc' }`   | sort the vuffers list                                                                                                      |
| `resize`                            | `width: string \| number`                                     | resize vuffers list window. If string such as "+10" or "-10" passed, the window size is increased or decreased accordingly |
| `increment_additional_folder_depth` |                                                               | show extra parent folder. however, sorting is still based on the filename (e.g. "something" for "a/b/c/something.json")    |
| `decrement_additional_folder_depth` |                                                               | opposite of `increment_additional_folder_depth`                                                                            |
| `pin_current_buffer`                |                                                               | pin current buffer. pinned buffer is placed on the top of the list                                                         |
| `unpin_current_buffer`              |                                                               | opposite of `pin_current_buffer`                                                                                           |
| `close_unpinned_buffers`            |                                                               | close all unpinned buffers. `config.handlers.on_delete_buffer` is called for each unpinned buffer.                         |
| `go_to_active_pinned_buffer`        |                                                               | go to currently active pinned buffer                                                                                       |
| `go_to_next_pinned_buffer`          |                                                               | go to next pinned buffer from the active one                                                                               |
| `go_to_prev_pinned_buffer`          |                                                               | go to previous pinned buffer from the active one                                                                           |
| `set_log_level`                     | `level: 'error' \| 'warning' \| 'info' \| 'debug' \| 'trace'` | update log level                                                                                                           |

<br>

## ⚡ Highlight Groups

- `VuffersWindowBackground`

- `VuffersActiveBuffer`

- `VuffersModifiedIcon`

- `VuffersPinnedIcon`

- `VuffersActivePinnedIcon`

<br>

## ⬆️ Ideas for improvements

- custom order
- sort by parents
  - for example `a/b/c.json` and `a/b/d.json` are grouped and sorted by `b`
- toggle full path from cwd
- filter by name
- (show Git signs)
- (show LSP diagnostics)
