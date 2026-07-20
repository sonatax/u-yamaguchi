# Stack-chan Driver for iOS

iPhoneで取得・判定した運転状態を、Bluetooth Low Energy（BLE）でStack-chanへ通知するiOSアプリです。第1段階ではセンシング処理を行わず、BLE Centralとしての接続と手動テスト送信を提供します。

## 動作環境

- iOS 17.0以降
- Xcode 26.2で作成（Swift / SwiftUI）
- 実機iPhone（BLE接続の確認に必要）
- 外部ライブラリなし

## BLE仕様

| 項目 | 値 |
| --- | --- |
| Peripheral名 | `StackChan-Driver` |
| Service UUID | `7DDA0001-5A5A-4E4F-9B3A-2E65F5A10001` |
| Event Write Characteristic UUID | `7DDA0002-5A5A-4E4F-9B3A-2E65F5A10001` |
| 書き込み方式 | `CBCharacteristicWriteType.withResponse` |
| ペイロード | 2バイト固定（イベントID、警告レベル） |

### イベントID

| イベント | 値 |
| --- | --- |
| 通常状態へ戻す | `0x00` |
| 運転開始 | `0x01` |
| 急ブレーキ | `0x02` |
| 長時間運転 | `0x03` |
| ドライバーの反応低下 | `0x04` |
| 眠気の可能性 | `0x05` |
| 運転終了 | `0x06` |

### 警告レベル

| レベル | 値 |
| --- | --- |
| 解除 | `0x00` |
| 軽度 | `0x01` |
| 中程度 | `0x02` |
| 強度 | `0x03` |

## 起動方法

1. `StackChanDriver.xcodeproj`をXcodeで開きます。
2. Signing & Capabilitiesで開発チームとBundle Identifierを環境に合わせます。
3. iOS 17以降のiPhoneを実行先に選び、Runします。
4. 初回起動時にBluetoothの利用を許可します。

## Stack-chanとの接続方法

1. Stack-chan側で、上記ServiceおよびCharacteristicを公開してAdvertisingを開始します。
2. Stack-chanのAdvertising名を`StackChan-Driver`にします。
3. アプリを起動すると自動スキャンが始まります。見つからない場合は「再スキャン」を押します。
4. 「Stack-chan」が「検出済み」になったら「接続」を押します。
5. 接続とCharacteristicが探索済みになれば送信可能です。

意図しない切断が発生した場合、アプリは直前に検出したPeripheralへ自動再接続します。「切断」を押した場合は再接続しません。

## テスト送信方法

接続後、「テスト送信」からイベントを選びます。急ブレーキ、長時間運転、反応低下、眠気は軽度・中程度・強度を選択できます。送信は2バイト固定長で行われ、PeripheralからのWrite Responseを受け取ると「送信結果」が成功になります。5秒以内に応答がなければタイムアウトになります。

## Info.plistの権限

プロジェクトはInfo.plistを自動生成し、次のキーをBuild Settingsに設定しています。

- `NSBluetoothAlwaysUsageDescription`: Stack-chanとの接続および運転状態イベント送信にBluetoothを使用する旨の説明

iOS 17ではBLE Centralの利用に位置情報権限は不要です。バックグラウンドでのBLE通信は初期実装の対象外のため、Background Modesは設定していません。

## テスト

XcodeのTest、またはXcodeが選択された環境で次を実行します。

```sh
xcodebuild test \
  -project StackChanDriver.xcodeproj \
  -scheme StackChanDriver \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 既知の制限

- 実際のセンサーデータ取得、運転状態判定、イベントの連続送信抑制は未実装です。
- バックグラウンド実行とBLE State Restorationには未対応です。
- 再接続は直前のPeripheralに対して行い、指数バックオフや再スキャンへの自動切り替えは未実装です。
- 同時に処理できるWrite Requestは1件です。
- Simulatorでは実PeripheralとのBLE通信を検証できないため、接続試験には実機が必要です。
