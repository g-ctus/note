---
ID: 202601151530
created: 2026-01-15 15:30
title: Neovimでstatuslineを完全に非表示にする方法
aliases: []
tags:
  - 2026/01/15
  - PERMANENT
  - Neovim
  - dotfiles
  - Publish/private
date: 2026-01-15
---

## 背景
[[statusline隠すとかっこよくなることに気づいてしまった... - 輪ごむの空き箱]]や[[思考を減らしコードに集中するための tmux, Neovim 設定]]で紹介されていたステータスラインの完全非表示を実現する．

Neovimで`laststatus=0`を設定しても、`:sp`や`:copen`で複数ウィンドウを開くとstatuslineが表示される.

[[laststatus = 0 doesn't remove statusline from horizontal splits · Issue 28488 · neovimneovim|仕様らしい]]

## 原因
`laststatus`オプションの仕様:
- `0`: ウィンドウが1つのときのみ非表示
- `1`: 複数ウィンドウのときのみ表示
- `2`: 常に表示
- `3`: グローバルstatusline（最下部に1つのみ）

複数ウィンドウでは境界としてstatuslineが必要なため、完全に消すことはできない.

## 解決策
statuslineを背景色と同化させて視覚的に非表示にする.

### 設定（init.lua）

```lua
vim.opt.laststatus = 0
vim.opt.statusline = "%{repeat('─',winwidth('.'))}"
   
-- StatusLine: sync background with Normal to hide statusline
local function setup_statusline_hl()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  local bg = normal.bg
  if bg then
    vim.api.nvim_set_hl(0, 'StatusLine', {  bg = bg })
    vim.api.nvim_set_hl(0, 'StatusLineNC', {  bg = bg })
  else
    vim.api.nvim_set_hl(0, 'StatusLine', { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { link = 'Normal' })
  end
end
```

## 愚痴
`:h laststatus`では，`laststatus = 0 never`としているのだから，`laststatus =0`で完全にステータスラインを消すように仕様を変更してほしい．
実装が難しいなら，laststatusの説明を更新してほしい．．．