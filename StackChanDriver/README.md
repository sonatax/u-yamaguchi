# Stack-chan Driver for iOS

iPhoneで取得・判定した運転状態を、Bluetooth Low Energy（BLE）でStack-chanへ通知するiOSアプリです。Core MotionとCore Locationによる自動見守り画面と、BLEを単独確認できる手動テスト画面を提供します。

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
4. 初回起動時にBluetooth、モーション、位置情報の利用を許可します。

## Stack-chanとの接続方法

1. Stack-chan側で、上記ServiceおよびCharacteristicを公開してAdvertisingを開始します。
2. Stack-chanのAdvertising名を`StackChan-Driver`にします。
3. アプリを起動すると自動スキャンが始まります。見つからない場合は「再スキャン」を押します。
4. 「Stack-chan」が「検出済み」になったら「接続」を押します。
5. 接続とCharacteristicが探索済みになれば送信可能です。

意図しない切断が発生した場合、アプリは直前に検出したPeripheralへ自動再接続します。「切断」を押した場合は再接続しません。

## テスト送信方法

「BLEテスト」タブで接続後、イベントを選びます。急ブレーキ、長時間運転、反応低下、眠気は軽度・中程度・強度を選択できます。送信は2バイト固定長で行われ、PeripheralからのWrite Responseを受け取ると「送信結果」が成功になります。5秒以内に応答がなければタイムアウトになります。運転見守り中は、自動送信との競合を避けるため手動送信を無効にします。

## 実センサーによる運転見守り

1. 「BLEテスト」タブでStack-chanへ接続します。
2. iPhoneを車載ホルダーへ固定します。
3. 「運転見守り」タブで「見守りを開始」を押します。
4. 初回はモーションおよび位置情報の利用を許可します。
5. 速度、加速度、運転判定、検出イベント、自動送信結果を画面で確認します。
6. 終了時は「見守りを終了」を押します。

自動判定の初期値は次のとおりです。実走行時の端末、設置方法、GPS環境に応じて調整してください。

| 判定 | 初期条件 |
| --- | --- |
| 運転開始 | 約10 km/h以上が5秒継続 |
| 運転終了 | 約3 km/h以下が120秒継続 |
| 急ブレーキ | 走行中の速度低下と0.12 G以上のモーションピークを併用 |
| 長時間運転・軽度 | 90分 |
| 長時間運転・中程度 | 120分 |
| 長時間運転・強度 | 180分 |

急ブレーキ後は8秒後に通常状態へ戻すイベントを送信します。同一イベントは15秒以内の連続送信を抑制します。ただし警告レベルが上昇した場合は即時送信します。

## Info.plistの権限

プロジェクトはInfo.plistを自動生成し、次のキーをBuild Settingsに設定しています。

- `NSBluetoothAlwaysUsageDescription`: Stack-chanとの接続および運転状態イベント送信にBluetoothを使用する旨の説明
- `NSMotionUsageDescription`: 急ブレーキ判定にモーションセンサーを使用する旨の説明
- `NSLocationWhenInUseUsageDescription`: 速度と運転状態判定に位置情報を使用する旨の説明

iOS 17ではBLE Central自体の利用に位置情報権限は不要ですが、本アプリでは走行速度の取得に位置情報を使用します。バックグラウンドでのセンサー取得とBLE通信は初期実装の対象外のため、Background Modesは設定していません。

## テスト

XcodeのTest、またはXcodeが選択された環境で次を実行します。

```sh
xcodebuild test \
  -project StackChanDriver.xcodeproj \
  -scheme StackChanDriver \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## 既知の制限

- ドライバーの反応低下と眠気のカメラ判定は未実装です。BLEテスト画面からは手動送信できます。
- 急ブレーキの初期判定値は一般的な目安であり、実車・端末設置条件に基づく調整が必要です。
- GPS精度が低い場所では運転開始・終了・急ブレーキを判定しません。
- バックグラウンド実行とBLE State Restorationには未対応です。
- 再接続は直前のPeripheralに対して行い、指数バックオフや再スキャンへの自動切り替えは未実装です。
- 同時に処理できるWrite Requestは1件です。
- Simulatorでは実PeripheralとのBLE通信を検証できないため、接続試験には実機が必要です。
