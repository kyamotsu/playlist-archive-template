# playlist-archive-template
Archive your YouTube Playlists.

workflow の定期実行によって、YouTube アカウントで作成した Playlist の情報を `archive/youtube/playlists` 下にアーカイブします。

## 使い方

### 初期設定


1. Repository を Fork する
    1. Repository を Private 化したい場合は、Fork でなく、Private な Repository を作成して、このレポジトリ内容を Push する
1. 必要な認証情報を設定する
    1. [Google Cloud Console](https://console.cloud.google.com/) OAuth 2.0 クライアント ID を作成する
        1. [Google Cloud Console](https://console.cloud.google.com/) に login
        1. Project を作成
        1. `ライブラリ` から `YouTube Data API v3` を有効にする
        1. OAuth クライアントを構成する
            1. `OAuth 同意画面` を選択し、`Google Auth Platform` を開始する
            1. アプリ名、メールアドレス等を設定して作成
            1. `対象` を選択して `アプリを公開` する
                1. `公開ステータス` が `テスト中` の場合、後ほど発行する `refresh token` が7日間で expire します
            1. `クライアント` を選択し、`OAuth クライアント` を作成する
                1. `アプリケーションの種類` から `デスクトップ アプリ` を選択する
                1. 適切な名前を設定して作成
                1. クライアントシークレットの JSON をダウンロードする
    1. `refresh token` を取得する
        1. `{CLIENT_ID}` を取得したものに置き換えて、ブラウザから以下にアクセス
            `https://accounts.google.com/o/oauth2/auth?client_id={CLIENT_ID}&redirect_uri=http://localhost&scope=https://www.googleapis.com/auth/youtube&response_type=code&access_type=offline`
        1. Archive する Google アカウントを選択
        1. `このアプリは Google で確認されていません` が表示されたら、`詳細` を選択して `{アプリ名} (安全でないページ) に移動` を選択
        1. 続行して、Google アカウントでアプリを許可する
        1. `http://localhost/?code={CODE}&scope=https://www.googleapis.com/auth/youtube` にリダイレクトされるので、URL から `{CODE}` 部分を取得する
        1. 取得した `{CODE}`, `{CLIENT_ID}`, `{CLIENT_SECRET}` を使用して、以下のようなリクエストによって `refresh token` を取得する
            ```
            curl -X POST \
              -H "Content-Type: application/json" \
              -d '{
                "code":"{CODE}",
                "client_id":"{CLIENT_ID}",
                "client_secret":"{CLIENT_SECRET}",
                "redirect_uri":"http://localhost",
                "grant_type":"authorization_code"
                }' \
              https://accounts.google.com/o/oauth2/token
            ```
        1. 必要な Github Secrets を設定する
            1. Repository の `Settings` -> `Secrets and variables` -> `Actions` を選択
            1. 取得した `CLIENT_ID`, `CLIENT_SECRET`, `REFRESH_TOKEN` をそれぞれ設定する
1. Workflow Permissions の設定
    1. `Setting` -> `Actions` -> `General` を選択
    1. `Workflow permissions` から `Read and write permissions` を選択して `Save`
1. Github Action の動作確認
    1. Repository の `Actions` -> `Archive Youtube Playlists` を選択
    1. `Run workflow` から workflow を実行
    1. workflow が成功して、`archive/youtube/playlists` 下に playlist の情報が commit されていることを確認する
1. 定期実行時刻を設定
    1. [.github/workflows/archive-youtube-playlists.yaml#L5](https://github.com/kyamotsu/playlist-archive/blob/main/.github/workflows/archive-youtube-playlists.yaml#L5) を編集して、実行頻度、時刻を設定する
        1. 実行頻度や Playlist 数によっては、Youtube API の request 制限に引っかかるので注意

### 削除された動画の patch
動画が削除された場合、取得した動画情報が
```
{
  "name": "Deleted Video",
  "description": "This video is unavailable",
}
``` 
のように表示されることがあります。
削除された動画の情報は、このレポジトリで過去にアーカイブした commit や Internet Archive などから title や description の情報を取得できることがあります。
この場合、`patch/youtube.json` に以下のように情報を追加することで、`Archive Youtube Playlists` の出力に上書きすることができます。
```
[
  {
    "id": "{削除された動画 id}",
    "name": "xxx",
    "description": "xxx"
  },
  {
    "id": "{削除された動画 id}",
    "name": "xxx",
    "description": "xxx"
  }
]
```
2025/09/03 現在、削除された動画情報も通常通り取得することができます
