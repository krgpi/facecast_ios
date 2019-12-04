# facecast_ios

Appleのサンプルプロジェクトをベースにしています。

## build setup
 `carthage update` を実行しパッケージをインストールする

## システム概要

iOSのARkit(FaceTracking)で、顔のblendshapesを取得

↓

サーバーに送信(SocketIO)

↓

クライアントWebアプリでVRMキャラクターの表情を動かす

(three-vrm)
