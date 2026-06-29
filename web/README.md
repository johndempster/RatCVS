# RatCVS Web

macOSでそのまま使えるブラウザ版RatCVSです。DelphiやWindows互換レイヤーは不要です。

リポジトリ直下で起動します。

```sh
python3 -m http.server 4173
```

ブラウザで開きます。

```text
http://127.0.0.1:4173/web/
```

主な操作:

- `開始` で新しい記録を進めます。
- `.rat 読込` または `サンプル` から既存のRatCVS記録を読み込みます。
- グラフ上にマウスを置くと、X軸時刻、各チャンネルのY軸ガイド、数値表が表示されます。
- グラフ領域そのものを横スクロールできます。
- グラフ上でホイールすると、マウス位置をアンカーにして拡大縮小できます。
- グラフ上部の `− / ＋` または `表示幅` スライダーでも、グラフを直接拡大縮小できます。

---

# RatCVS Web (English)

A browser-based version of RatCVS that runs as-is on macOS. No Delphi or Windows compatibility layer is required.

Start it from the repository root.

```sh
python3 -m http.server 4173
```

Open it in your browser.

```text
http://127.0.0.1:4173/web/
```

Main controls:

- Press `開始` (Start) to begin a new recording.
- Load an existing RatCVS recording from `.rat 読込` (Load .rat) or `サンプル` (Sample).
- Hover over the chart to show the X-axis time, per-channel Y-axis guides, and a value table.
- The chart area itself can be scrolled horizontally.
- Scroll the wheel over the chart to zoom in/out, anchored at the mouse position.
- You can also zoom the chart directly with `− / ＋` at the top of the chart or the `表示幅` (display width) slider.
