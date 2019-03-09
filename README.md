# facecast_ios

Based on Apple Sample
Appleのサンプルプロジェクトをベースにしています。

iPhoneからVtube配信を行うことを目標としたアプリ、**facecast(仮)** をiOS配信アプリ, Webビューワーアプリの両方で一体開発しています。

## システム概要

iOSのARkit(FaceTracking)で、顔のblendshapesを取得

↓

AWS サーバーに送信(SocketIO)

↓

クライアントWebアプリでVRMキャラクターの表情を動かす

(threejs, VRMloader)



このレポジトリは、web viewer(repo:facecast_webView)とセットで使います。

This web App works with web viewer(repo:facecast_webView).


