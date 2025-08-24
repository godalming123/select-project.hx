# `select-project.hx`

A helix plugin to select a project to be helix's working directory with fuzzy finding.

# Installation

- [Install a version of helix that supports plugins](https://github.com/mattwparas/helix/blob/steel-event-system/STEEL.md)
- Clone `select-project.hx`:
  ```sh
  git clone https://github.com/godalming123/select-project.hx ~/.config/helix/select-project.hx/
  ```
- Add `select-project.hx` to `~/.config/helix/init.scm`:
  ```diff
  +(require "select-project.hx/main.scm")
  ```
- Add a keybinding to trigger the `select-project` command in `~/.config/helix/config.toml`:
  ```diff
  +[keys.normal.g]
  +p = ":select-project"
  ```

# Todo

- Highlight the part of the project that fuzzy matched the search query
- Use a bar for a cursor instead of a block
- Use an elipses when project names are too long to fit in the picker
- Use an elipses and scroll the search query input when it's contents is too long to fit in the picker
- Show the file picker after the project has been picked
- Be able to bind keys to open projects from the project picker
