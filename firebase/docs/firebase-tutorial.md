class: center,middle
# Firebase を用いて ToDo アプリ を動かそう！

スライド表示の場合、キーボードの**左右**で操作できます

---

## アプリ画面イメージ

.left-column[PC]

.right-column[スマホ]

.left-column[![:scale 90%](https://i.imgur.com/rULzRnp.png)]

.right-column[![:scale 40%](https://i.imgur.com/JRmyXfI.png)]
---
## ファイル構成

```bash
firebase
├── README.md
├── database.rules.json
├── firebase.json
├── firestore.indexes.json
├── firestore.rules
└── public
    └── sample.html
```
---
## 注意事項

* ブラウザからソースコードをコピペされると他の人からも操作できる状態になっているので、自由にデータベースを更新できてしまいます。そのまま公開（他人にリンクを教えるなど）はしないで下さい
* 公開したい場合は Firebase Authentication の機能を利用して、別途ユーザー作成、権限管理をするなどの認証機能を導入しましょう。
* Firebase はクレジットカードを登録せずに利用できます。無料枠を使い切った場合はサーバなどの稼働が止まってしまうので注意しましょう。
* ただし、本格的にサービスを公開する場合など、上位のプランを選択した場合には **課金が発生します**。詳しくは [こちら](https://firebase.google.com/pricing/) をご確認下さい。
---
## 前提

* ここでは、Firebase の初期設定の仕方と、サンプルコードを動かします。エディタ（テキスト編集ソフト）や Git に関する説明は行いません、また、コードを編集することも行いません。
* 使用するエディターは自由ですが、質問対応等の場合に環境があっていることが望ましいため、特別こだわりがなければ**VSCode**を推奨します。
* Macでの操作を前提としております。Firebaseの操作等は基本的にはどのOSでも変わらないため、Windowsでも開発可能ですがここでの説明ではカバーしていません。
* 2021/09/14 現在の情報です。Firebase に関する最新の情報は [公式ページ](https://firebase.google.com/) をご確認下さい
---
## 主な利用技術/ツール

* Firebase CLI:
 * ターミナルからFirebaseの設定や操作を行うためのコマンドラインツール
* Firebase Hosting:
 * Webサイトを提供できる機能
* Firebase Cloud Firestore:
 * データベース(NoSQL)
---
## このチュートリアル完了までの目安時間

* 1時間程度

## 検証済みの環境

* OSX Catalina 10.15.5
* Firebase CLI 8.6.0
* jQuery 3.5.1
* firebasejs 6.2.0
---
layout:true
## Firebaseにログインし、プロジェクトを作る
---

 https://firebase.google.com/?hl=ja へアクセスし、「コンソールへ移動」を選択します。

![:scale 60%](./images/page8.png)
---

Googleアカウントでログインします。

※学校等の発行したGoogleアカウントの場合、<br>Firebaseを利用できない場合があります。
その場合は個人のアカウントでログインし直してください。

![:scale 60%](https://i.imgur.com/NWhMIMa.png)
---

再度、「コンソールへ移動」を選択します。

![:scale 60%](./images/page8.png)
---

プロジェクトを作成します。

![:scale 70%](./images/page11.png)
---

プロジェクト名を入力し、Firebaseの規約に同意します。

プロジェクト名は任意の文字列(英数字)でOKです。図の例：firebase-test-2026

![:scale 80%](./images/page12.png)
---

AI アシスタントを有効にするか聞かれますが、今回は有効化しません。

チーム開発で firebase を利用する際には有効化してもOKです。

![:scale 80%](./images/page13.png)
---

Google アナリティクスを有効化します。（必須ではありません）

アナリティクス用のアカウントを求められた場合はDefaultのアカウントを選びましょう。

.left-column[![:scale 110%](./images/page14-1.png)]

.right-column[![:scale 110%](./images/page14-2.png)]

---

これでプロジェクトの準備は完了です

![:scale 40%](./images/page15.png)

---
layout:true
## データベース（Firestore）の作成
---

次に、Firestore の機能を使ってデータベースを作成します。

左のメニューから「Firestore Database」（Cloud Firestore）を選択して下さい。

![:scale 70%](./images/page16.png)
---

このような画面になったら「データベースの作成」を行います。

![:scale 50%](./images/page17.png)
---

「Standardエディション」を選択します。

![:scale 60%](./images/page18.png)
---

ロケーションを選択します。（`asia-northeast1(Tokyo)` がオススメ）

![:scale 60%](./images/page19.png)
---

「本番環境モードで開始」を選択します。

![:scale 60%](./images/page20.png)

「有効にする」を押した後、数十秒ほど待って、画面が移行すればここの作業は完了です。

[Cloud Firestore](https://firebase.google.com/docs/firestore/quickstart?authuser=1) についての説明はこちらから確認できます。

---
layout:true
## Firebase CLI を利用した Deploy
---

左のメニューの「プロジェクトの概要」をクリックし、

「アプリを追加」をクリックしたあとのウェブアイコン 「`</>`」 をクリックしてください。
![:scale 65%](./images/page21.png)

---

アプリのニックネームを入力(今回は`test`)し、Firebase Hostingにチェックをつけたあと、「アプリの登録」をクリック

![:scale 70%](./images/page22.png)

---

「次へ」を選択します。

「Firebase SDKの追加」,「Firebase CLI のインストール」の作業は今回は不要のため「次へ」を押してください。

（用意されているコードに既にSDKが追加されているため）

※Firebase CLIのインストールはこの後行います。

![:scale 60%](./images/page23.png)

---

※先ほどまでのfirebaseの画面はそのままにしておき、別のタブやウインドウで作業してください。

[GitHubのページ](https://github.com/sonatax/u-yamaguchi/)から
`[Code]`メニューの中の「Download ZIP」でダウンロードをし、zipファイルの展開をしましょう。
展開したzipファイルの中にある firebase を利用します。

![:scale 60%](./images/page24.png)

---

Firebase CLI をインストールします。

https://firebase.google.com/docs/cli?hl=ja にアクセスしてください。

ご自分の環境に合わせてページの指示に従ってインストールしてください。

基本的に、下記の選択をお勧めします
- Windowsの場合は「スタンドアロンバイナリ」
- Macの場合は「自動インストールスクリプト」

firebase login は後のスライドで行うのでここではしなくてOKです

※npmを使える方はnpmでインストールする形でも大丈夫です。

※Windowsの場合、ダウンロードに使うブラウザはChromeなど、Edge以外を推奨します

※Windowsの場合、exeファイル起動時に「WindowsによってPCが保護されました」という画面が出る場合があります。この表示が出たら「詳細情報」をクリックした後「実行」をクリックするとFirebaseCLIが起動できます
---

ここからは画面上の指示に従って、デプロイ（Web上へのアップロード）を実施します。

![:scale 70%](./images/page26.png)

---

Firebase CLI でログインを実施します。下記のコマンドを入力して実行してください。

その後自動で開かれるブラウザでFirebaseのGoogleアカウントへのアクセスを許可してください。

```shell
$ firebase login
```

![:scale 85%](./images/page27.png)

※Windows の場合FirebaseCLIを起動したタイミングでログインが実施される場合があります。
その場合は上記のコマンドはスキップし、ブラウザでの操作に進んでください。

※Windowsの場合、セキュリティファイアウォールの画面が開く場合があります。その場合は許可して次に進んでください。

---

先ほどGitHubからzipファイルをダウンロードし、展開したフォルダにターミナル上で移動します。

展開される場所は人によって違うので、自分の場合に合わせて調整してください

Windowsの場合の例
```bash
cd C:¥Users¥ユーザー名¥Downloads¥firebase_tutorial-master¥firebase_tutorial-master
```
Macの場合
```bash
cd /Users/ユーザー名/Downloads/firebase_tutorial-master
```

`ls`あるいは`dir`コマンドで下のようなファイルが表示されていればOKです
```bash
❯ ls
README.md               firebase.json           public/
database.rules.json     firestore.indexes.json
docs/                   firestore.rules
```
---

`firebase init` コマンドを実行して、いくつか質問をされるので space で回答します。

```shell
$ firebase init
```
「Are you ready to proceed?」はそのままEnter

キーボードの上下でカーソルを移動させ、
*Firestore: Configure security rules and indexes files for Firestore* と
*Hosting: Configure files for Firebase Hosting and (optionally) set up GitHub Action deploys*
の **2つ** を space で選択して、Enter を押下します。

![:scale 50%](./images/page29.png)

---

![:scale 90%](https://i.imgur.com/4gh1FRo.png)

次の質問 `Please select an option:` には `Use an existing project` を Enter で選択します。

![](https://i.imgur.com/qXP3LOp.png)
---

`Select a default Firebase project for this directory: ` には、先程作成したプロジェクト名を上下キーで合わせ Enter で選択しましょう。（以前に Firebase を別の用途で使用したことがある人は複数提示されます）

![](./images/page31.png)
---

Firestore Setup と出てくる

`What file should be used for Firestore Rules? ` には何も選択せず Enter

`File firestore.rules already exists. Do you want to overwrite it with the Firestore Rules from the Firebase Console?` は `N` を入力して Enter

※ 上の質問はでなければスルーしてOK

`What file should be used for Firestore indexes?` は何も選択せず Enter

`File firestore.indexes.json already exists. Do you want to overwrite it with the Firestore Indexes from the Firebase Console?` は `N` を入力して Enter

※ 上の質問はでなければスルーしてOK

![](./images/page32.png)

---

`? What do you want to use as your public directory?` は何も選択せず Enter

`Configure as a single-page app (rewrite all urls to /index.html)? (y/N) ` は `y` を入力して Enter

`Set up automatic builds and deploys with GitHub` は `n` を入力して Enter

最後に `Would you like to install agent skills for Firebase?` は `n` を入力して Enter

![](./images/page33.png)

---

ここまで実施できたら、`firebase serve` で このレポジトリのプログラムを動かしてみましょう。

```shell
$ firebase serve
```

下記のようなコマンドの実行結果となるので、表示された http://localhost:5002 をブラウザで開いてみましょう。

![](https://i.imgur.com/Xo7o2iu.png)

---

下記のように表示されれば成功です。(Firebaseを初期化した際に作成されるテストページ)

このページは実行しているパソコンでしか見ることができないページなので、まだ自分しか見られない状態です。

![:scale 70%](https://i.imgur.com/G9JK7Ot.png)

---

`firebase serve`はターミナルを選択した状態で、`Control + C` (Windowsの場合は `Ctrl + C`) で停止します。

動作が確認できたら、Firebase Hosting の機能を利用して、クラウド（インターネット）上に Deploy します。

```shell
$ firebase deploy
```

Deploy 後、ターミナルに表示された「Hosting URL: 」のURLか、
ブラウザの下記で表示されるリンクからアクセスします。

![](https://i.imgur.com/QyLuqWO.png)

---

先ほどと同じように下記のように表示されれば成功です。

これで、このページはインターネット上に公開され、他の人からも閲覧できる状態になりました。

![:scale 50%](https://i.imgur.com/G9JK7Ot.png)

`firebase serve` ではローカル上（自分のPC上）でプログラムを実行させているのに対し、`firebase deploy` ではクラウド上に Deploy してインターネット上に公開させているということに注意しましょう。

---
layout:true
## HTML の編集が反映されることを確認する
---

次に、自分のプロジェクトで `public/index.html` をエディタ（テキスト編集ソフト）などで開き、下記箇所を変更します。

`public/index.html`

変更前
```htmlembedded=34
<div id="message">
  <h2>Welcome</h2>
  <h1>Firebase Hosting Setup Complete</h1> <!-- この行を編集 -->
  <p>You're seeing this because you've successfully setup Firebase Hosting. Now it's time to go build something extraordinary!</p>
  <a target="_blank" href="https://firebase.google.com/docs/hosting/">Open Hosting Documentation</a>
</div>
<p id="load">Firebase SDK Loading&hellip;</p>
```
---

変更後

```htmlembedded=34
<div id="message">
  <h2>Welcome</h2>
  <h1>テスト</h1><!-- テストという文章に変えた。 -->
  <p>You're seeing this because you've successfully setup Firebase Hosting. Now it's time to go build something extraordinary!</p>
  <a target="_blank" href="https://firebase.google.com/docs/hosting/">Open Hosting Documentation</a>
</div>
<p id="load">Firebase SDK Loading&hellip;</p>
```

変更が完了したら、firebase serveで確認をします

```shell
$ firebase serve
```
---

#### ※変更の反映のさせ方について、
firebase serveコマンドは実行したままでファイルの変更を行って構いません。<br>

ファイルの変更ができたらページをリロードします。
このとき、前回のページの情報（キャッシュ）が残っていると、うまく反映されない場合があります。

画面の更新を行うときはキャッシュを削除したリロード（スーパーリロード）を行うようにしましょう。

Mac
```bash
Command + Shift +R
```
Windows
```bash
Ctrl + Shift +R
```
---

下記のようにWelcomeの文字列がテストに変更されていれば完了です。

（自分の好きな文章に変えて試してもOKです）

![:scale 70%](https://i.imgur.com/1C4bh8m.png)

---
layout:true
## ToDo アプリ を動かしてみる
---

いよいよTodoアプリを動かしてみましょう。

既存の index.html をバックアップしたうえで、sample.htmlを index.html に置き換えます。

```shell
$ mv public/index.html public/_index.html 
$ cp public/sample.html public/index.html
```
※コマンドでの変更でなくとも、publicフォルダの中のファイル名が、「index.html」→「_index.html」に、「sample.html」→「index.html」に変更できていればOKです。

![:scale 20%](https://imgur.com/5VAAAuN.png)

---

ローカルで確認します。

```shell
$ firebase serve
```

`firebase serve`ができたら、先ほどと同じ URL をブラウザから開き、下図のような表示になるかを確認します。[こちら](https://www.atmarkit.co.jp/ait/articles/1403/20/news050.html) の方法を用いて、PC上でもスマホでの挙動をエミュレートして確認する事ができます。


.left-column[PC]

.right-column[スマホ]

.left-column[![:scale 90%](https://i.imgur.com/rULzRnp.png)]

.right-column[![:scale 45%](https://i.imgur.com/JRmyXfI.png)]

---

うまく動くことを確認できたら、deployをして公開しましょう
```shell
$ firebase deploy
```

### これでFirebaseチュートリアルは終了です！お疲れさまでした

*実際にどう動いているか、という点についてはソースコードにコメントをつけて簡単に説明を加えています。[Firebase のドキュメント](https://firebase.google.com/docs/) と合わせてご確認下さい。*

余力があれば、`firebase serve`で確認しながら、少しずつ自分でコードにアレンジを加えてみてみると良い学習になると思います！

---
layout:false
## その他、Firebase の機能例

* [Firebaseの各機能を3行で説明する](https://qiita.com/shibukk/items/4a015c5b3296563ac19d)

## 参考リンク　

* [Google の Firebase サンプル](https://firebase.google.com/docs/samples?authuser=1#web)
* [Firebase入門 フリマアプリを作りながら、認証・Firestore・Cloud Functionsの使い方を学ぼう！](https://employment.en-japan.com/engineerhub/entry/2019/06/07/103000)
