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


## 各ファイルの説明
### iOS - Web (eyeGaze.swift)

eyeTransformをサーバーに送信します。ウェブビューワーでVRMキャラクターの表情が動くことを確認できます。

### iOS - iOS (emotion.swift)

blendShapes配列をサーバーに送信します。ウェブビューワーは未対応ですが、後述するViewerで表情が通信できてることが確認できてました。（なんかできなくなったので、調整中です）


### Viewer (receiveViewController.swift)

サーバーからblendShapes配列を受信します（現在できません）。成功すれば表情が動きます。
