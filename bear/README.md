# 山口県 熊出没マップ

`bear/data` 配下の CSV を Google Maps 上に表示する静的ページです。

## ファイル

- `index.html`: 地図表示アプリ
- `data/r6-01051231.csv`: 令和6年データ
- `data/r7-010112312.csv`: 令和7年データ

## 使い方

1. Google Cloud Console で Maps JavaScript API を有効化します。
2. API キーを作成し、必要に応じて HTTP リファラー制限を設定します。
3. `bear/index.html` を Web サーバー経由で開きます。
4. 画面左の入力欄に API キーを入れて「表示」を押します。

API キーはリポジトリには保存されません。ブラウザの `localStorage` にだけ保存されます。

URL パラメータで渡す場合は次の形でも表示できます。

```text
index.html?key=YOUR_GOOGLE_MAPS_API_KEY
```

## 表示仕様

- `r6-01051231.csv` は赤いピン
- `r7-010112312.csv` は青いピン
- 緯度または経度が `0` の行は表示対象から除外
- 警察署、場所、状況、日時で検索可能
- CSV 内の改行入りフィールドに対応
- UTF-8 / UTF-16LE / UTF-16BE の BOM を判定して読み込み

## 注意

ブラウザの `file://` で直接開くと、CSV の `fetch` がブロックされることがあります。ローカル確認時は `bear` ディレクトリで簡易サーバーを起動してください。

```sh
python3 -m http.server 8000
```

その後、`http://localhost:8000/` を開きます。
