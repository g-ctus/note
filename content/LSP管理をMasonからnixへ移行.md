---
title: LSP管理をMasonからnixへ移行
created: 2026-04-23
ID: 20260423090203
tags:
  - PERMANENT
  - neovim
  - lsp
  - tech_lang/nix
  - Publish/private
media:
aliases:
---

Language Server Protocol (LSP) をneovimで手っ取り早く使うため，LSPインストールを[mason.nvim](https://github.com/mason-org/mason.nvim)で行うのが主流かと思います．しかし[Masonで管理されているLSPはnixとの親和性が悪い](https://qiita.com/Sumi-Sumi/items/eda5894c0918f15ba971)ことが報告されています．
折角なのでLSPの管理もnixに任せてしまいましょう！

## nixpkgsからLSPを取得

`nixpkgs`経由で比較的簡単に設定できます．`default.nix`に以下を追加しましょう．

```nix:default.nix
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = true;

    initLua = builtins.readFile ./init.lua;

+    # LSPサーバーをNixで直接提供
+    extraPackages = with pkgs; [
+      python3Packages.python-lsp-server  # pylsp
+      texlab
+      ltex-ls
+      efm-langserver
+      lua-language-server                # lua_ls
+      nil                                # nil_ls
+      fortls
+    ];
  };
```
