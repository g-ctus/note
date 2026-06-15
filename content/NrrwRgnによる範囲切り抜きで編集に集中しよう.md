---
title: NrrwRgnによる範囲切り抜きで編集に集中しよう
created: 2026-04-12
ID: 20260412091638
tags:
  - created/2026-04-12
  - PERMANENT
  - vim
  - vim/dein
  - Outliner
  - Publish/private
media:
aliases:
date: 2026-04-12
---
文章を書くとき、ファイル全体から部分単位を切り抜いて集中して編集したいときがある。
そういうときには[NrrwRgn](https://github.com/chrisbra/NrrwRgn)を使えば良い。

ヴィジュアルモードで選択した範囲を、`:NRR`で新しいバッファに切り出せる。
編集が終わったら`:q`でバッファを抜ければ、元々のバッファに変更が反映される。

deinでの設定例を書いておく

```toml
repo = 'chrisbra/NrrwRgn'
on_cmd = ['NR', 'NRR', 'NarrowRegion', 'NW', 'NarrowWindow']
hook_add = '''
  let g:nrrw_rgn_nomap_Nr = 1
  let g:nrrw_rgn_nomap_nr = 1
  command! -range NRR '<,'>NR!
'''
hook_source = '''
  set hidden
  augroup NrrwRgnCustom
    autocmd!
    autocmd BufEnter * if exists('b:nrrw_instn') | setlocal readonly nomodifiable | endif
  augroup END
'''
```

`hook_add`の最初二行に書かれた設定は、デフォルトのキーマップを無効にしている。
3行目の`command! -range NRR '<,'>NR!`は`NrrwRgn`で,一度切り抜いたバッファから更に切り出せるようにしている。

`NrrwRgn`では元々のバッファをreadonlyにして保護する設定があるが、
上記のような設定をしたので、`hook_source`では元のバッファを編集不可能になるよう明示的に宣言している。