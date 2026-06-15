---
title: kensaku-vimによるローマ字入力で日本語検索
created: 2026-04-27
ID: 20260427054225
tags:
  - PERMANENT
  - vim/dein
  - vim/denops
  - Publish/private
media:
aliases:
---
[vim-kensaku-search](https://github.com/lambdalisue/vim-kensaku-search.git)を導入して，vimでローマ字検索できるようにする．
なおdein.vimで遅延読み込みさせる設定も示す．

導入後，例えば`/pura`と検索すれば`"プラ"スチック`や`カッ"プラ"ーメン`とかを検索で拾ってきてくれるようになる．

## 設定

```toml:dein_lazy.toml
[[plugins]]
repo = 'lambdalisue/vim-kensaku'

[[plugins]]
repo = 'lambdalisue/vim-kensaku-search'
depends = ['vim-kensaku', 'denops.vim']
on_event = ['CmdlineEnter']
on_if = 'getcmdtype() ==# "/" && search("[ぁ-んァ-ヶ一-龠々]", "nw") > 0'
hook_source = '''
  cnoremap <CR> <Plug>(kensaku-search-replace)<CR>
'''
```

コマンドラインに入ったときに`on_if`が発火し，
- `/`でコマンドラインに入ったか
- バッファに日本語が含まれているか
のandがとれたとき，プラグインを読み込む．

---

コマンドラインに入るたびにバッファ全体を走査するので，巨大ファイルで走査がもたつくようであれば，別途autocmdの導入を検討する．