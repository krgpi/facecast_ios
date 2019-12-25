//
//  emitViewController.swift
//  emit blendshapes array to socket connection.
//
//  Created by y.k. noaki on 2019/01/31.
//

import ARKit
import SceneKit
import UIKit
import WebKit
import ReplayKit
import Charts
//import SocketIO

class emitViewController: UIViewController {

	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet weak var tabBar: UITabBar!
	@IBOutlet weak var debugLabelView: UILabel!
	@IBOutlet var webView: WKWebView!
	@IBOutlet weak var urlInputField: UITextField!
	@IBOutlet weak var iosChartsFigure: LineChartView!
	
	var timer: Timer!
	var nowTime: Float = 0.0
	
	var defFaceDir: Float =  0.0
	var defL: Float = 0.0
	var defR: Float = 0.0
	
//	var socket = SocketIOManager()
	var confusedTime: [Float] = [0.0]
	var emitArrayHistory: [String: [ChartDataEntry]] = ["eyeL": [], "eyeR": [], "faceDir": []]
	var emitArray:[String: Float] = ["eyeL": 0.00, "eyeR": 0.00, "faceDir": 0.00]
	var contentControllers: [VirtualContentType: VirtualContentController] = [:]
	var selectedVirtualContent: VirtualContentType! {
		didSet {
			guard oldValue != nil, oldValue != selectedVirtualContent
				else { return }
			
			// Remove existing content when switching types.
			contentControllers[oldValue]?.contentNode?.removeFromParentNode()
			
			// If there's an anchor already (switching content), get the content controller to place initial content.
			// Otherwise, the content controller will place it in `renderer(_:didAdd:for:)`.
			
			if let anchor = currentFaceAnchor, let node = sceneView.node(for: anchor),
				let newContent = selectedContentController.renderer(sceneView, nodeFor: anchor) {
				node.addChildNode(newContent)
			//print(anchor.transform) //世界座標における現在の顔の位置と向き これを原点に顔座標系が作られる
			//print(anchor.geometry) //現在の顔の寸法、形状 これで顔の形に沿ってコンテンツを被せられる
			//print(anchor.blendShapes) //表情
			//print(newContent)
			}
		}
	}
	var selectedContentController: VirtualContentController {
		if let controller = contentControllers[selectedVirtualContent] {
			return controller
		} else {
			let controller = selectedVirtualContent.makeController()
			contentControllers[selectedVirtualContent] = controller
			return controller
		}
	}

	var currentFaceAnchor: ARFaceAnchor?

	// MARK: - View Controller Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()
//		socket.establishConnection()
//		socket.socketIOClient.emit("client_to_server_join", 1)
		sceneView.delegate = self
		sceneView.session.delegate = self
		sceneView.automaticallyUpdatesLighting = true
		
		// Set the initial face content.
		selectedVirtualContent = VirtualContentType(rawValue: 0)
		
		let webUrl = URL(string: "https://www.google.com/?hl=ja")!
		let myRequest = URLRequest(url: webUrl)
		webView.load(myRequest)
		setChart()
		
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// AR experiences typically involve moving the device without
		// touch input for some time, so prevent auto screen dimming.
		UIApplication.shared.isIdleTimerDisabled = true
		
		// "Reset" to run the AR session for the first time.
		resetTracking()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
//		socket.closeConnection()
	}
}

	// MARK: - ARSessionDelegate
extension emitViewController: ARSessionDelegate {
	func session(_ session: ARSession, didFailWithError error: Error) {
		guard error is ARError else { return }
		
		let errorWithInfo = error as NSError
		let messages = [
			errorWithInfo.localizedDescription,
			errorWithInfo.localizedFailureReason,
			errorWithInfo.localizedRecoverySuggestion
		]
		let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
		
		DispatchQueue.main.async {
			self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
		}
	}

	/// - Tag: ARFaceTrackingSetup
	func resetTracking() {
		guard ARFaceTrackingConfiguration.isSupported else { return }
		let configuration = ARFaceTrackingConfiguration()
		configuration.isLightEstimationEnabled = true
		sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
	}

	// MARK: - Error handling

	func displayErrorMessage(title: String, message: String) {
		// Present an alert informing about the error that has occurred.
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
			alertController.dismiss(animated: true, completion: nil)
			self.resetTracking()
		}
		alertController.addAction(restartAction)
		present(alertController, animated: true, completion: nil)
	}
}

	// MARK: - UITabBarDelegate
extension emitViewController: UITabBarDelegate {
	func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		guard let contentType = VirtualContentType(rawValue: item.tag)
			else { fatalError("unexpected virtual content tag") }
		selectedVirtualContent = contentType
	}
}

	// MARK: -ARSCNViewDelegate
extension emitViewController: ARSCNViewDelegate {
		
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		guard let faceAnchor = anchor as? ARFaceAnchor else { return }
		currentFaceAnchor = faceAnchor
		
		// If this is the first time with this anchor, get the controller to create content.
		// Otherwise (switching content), will change content when setting `selectedVirtualContent`.
		if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
			node.addChildNode(contentNode)
		}
	}
	
	/// - Tag: ARFaceGeometryUpdate
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard anchor == currentFaceAnchor,
			let contentNode = selectedContentController.contentNode,
			contentNode.parent == node
			else { return }
		guard let faceAnchor = anchor as? ARFaceAnchor
			else { return }
//		var blendShapes = faceAnchor.blendShapes
		emitArray["eyeL"] = round(asin(faceAnchor.leftEyeTransform.columns.2.x)*100) - defL
		emitArray["eyeR"] = round(asin(faceAnchor.rightEyeTransform.columns.2.x)*100) - defR
		emitArray["faceDir"] = round(asin(faceAnchor.transform.columns.2.x)*100) - defFaceDir
		DispatchQueue.main.async {
			self.debugLabelView.text = "time: \(round(self.nowTime*100)/100), L: \(self.emitArray["eyeL"] ?? 0), R: \(self.emitArray["eyeR"] ?? 0), face: \(self.emitArray["faceDir"] ?? 0), confused: \((round(self.confusedTime.last ?? 0.0)*100)/100)"
		}
//		do {
//			let e = try JSONSerialization.data(withJSONObject: emitArray, options: .prettyPrinted)
//			let str = String(bytes: e, encoding: .utf8)
//			socket.socketIOClient.emit("chat message", str!)
//		} catch  {
//			print("err")
//		}
		selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
	}
}

// MARK: Button
extension emitViewController {
	
	@IBAction func setZero(_ sender: UIButton) {
		defFaceDir = emitArray["faceDir"]  ?? 0.0
		defL = emitArray["eyeL"] ?? 0.0
		defR =  emitArray["eyeR"] ?? 0.0
	}
	
	@IBAction func exportData(_ sender: UIButton?) {
		let image = iosChartsFigure.getChartImage(transparent: true)
		UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
	}
	
	@IBAction func startRecord(_ sender: UIButton) {
		if timer?.isValid ?? false {
			timer.invalidate()
			sender.titleLabel?.text = "Start"
		} else {
			timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
			timer.fire()
			sender.titleLabel?.text = "Stop"
		}
	}
	
	@IBAction func confuseButton(_ sender: UIButton) {
		confusedTime.append(nowTime)
		let image = iosChartsFigure.getChartImage(transparent: true)
		UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
	}
	
	@objc func update(tm: Timer) {
		if emitArrayHistory["faceDir"]?.count ?? 0 > 100 {
			emitArrayHistory["faceDir"]?.removeFirst()
			emitArrayHistory["eyeL"]?.removeFirst()
			emitArrayHistory["eyeR"]?.removeFirst()
		}
		nowTime += 0.100000000000
		guard let dataF = emitArray["faceDir"] else {
			return
		}
		let dataEntryF = ChartDataEntry(x: Double(nowTime), y: Double(dataF))
		emitArrayHistory["faceDir"]?.append(dataEntryF)
		let dataEntryL = ChartDataEntry(x: Double(nowTime), y: Double(emitArray["eyeL"] ?? 0.0))
		emitArrayHistory["eyeL"]?.append(dataEntryL)
		let dataEntryR = ChartDataEntry(x: Double(nowTime), y: Double(emitArray["eyeR"] ?? 0.0))
		emitArrayHistory["eyeR"]?.append(dataEntryR)
		drawLineChart(emitArrayHistory)
	}
	
	@IBAction func goButtonDidTouchUpInside(_ sender: UIButton) {
		guard let urlstr = urlInputField.text else {
			return
		}
		guard let webUrl = URL(string: urlstr) else {
			return
		}
		let myRequest = URLRequest(url: webUrl)
		webView.load(myRequest)
	}
	
}

// MARK:Screen Capture
//extension emitViewController {
//
//	@IBAction func toggleRecording(_ sender: UIButton) {
//		let rpScreenRecorder = RPScreenRecorder.shared()
//		guard rpScreenRecorder.isAvailable else {
//			print("Replay Kit is unavailable")
//			return
//		}
//		if rpScreenRecorder.isRecording {
//			self.stopRecording(sender, rpScreenRecorder)
//		} else {
//			self.startRecording(sender, rpScreenRecorder)
//		}
//	}
//
//	func startRecording(_ sender: UIButton, _ recorder: RPScreenRecorder){
//		recorder.startRecording(handler:{ error in
//			if error == nil {
//				sender.setTitle("Stop", for: .normal)
//			} else {
//				print(error)
//			}
//		})
//	}
//
//	func stopRecording(_ sender: UIButton, _ recorder: RPScreenRecorder){
//		recorder.stopRecording(handler: { previewViewController, error in
//			sender.setTitle("Record", for: .focused)
//			if let pvc = previewViewController {
//				if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
//					pvc.modalPresentationStyle = UIModalPresentationStyle.popover
//					pvc.popoverPresentationController?.sourceRect = CGRect.zero
//					pvc.popoverPresentationController?.sourceView = self.view
//				}
//
//				pvc.previewControllerDelegate = self
//				self.present(pvc, animated: true, completion: nil)
//			}
//			else if let error = error {
//				print(error.localizedDescription)
//			}
//		})
//	}
//}

// MARK::Graph
extension emitViewController {
	
	func setChart(){
		guard let iosChartsFigure = self.iosChartsFigure else {
			return
		}
		print(iosChartsFigure)

		iosChartsFigure.noDataText = "You need to provide data for the chart."
		//x軸設定
		iosChartsFigure.xAxis.labelPosition = .bottom //x軸ラベル下側に表示
		iosChartsFigure.xAxis.labelFont = UIFont.systemFont(ofSize: 11) //x軸のフォントの大きさ
		iosChartsFigure.xAxis.labelCount = Int(10) //x軸に表示するラベルの数
		iosChartsFigure.xAxis.labelTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) //x軸ラベルの色
		iosChartsFigure.xAxis.axisLineColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) //x軸の色
		iosChartsFigure.xAxis.axisLineWidth = CGFloat(1) //x軸の太さ
		iosChartsFigure.xAxis.drawGridLinesEnabled = false //x軸のグリッド表示(今回は表示しない)
		//			iosChartsFigure.xAxis.valueFormatter = lineChartFormatter() //x軸の仕様
		
		
		//y軸設定
		iosChartsFigure.rightAxis.enabled = false //右軸(値)の表示
		iosChartsFigure.leftAxis.enabled = true //左軸（値)の表示
		iosChartsFigure.leftAxis.axisMaximum = 100 //y左軸最大値
		iosChartsFigure.leftAxis.axisMinimum = -100 //y左軸最小値
		iosChartsFigure.leftAxis.labelFont = UIFont.systemFont(ofSize: 11) //y左軸のフォントの大きさ
		iosChartsFigure.leftAxis.labelTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) //y軸ラベルの色
		iosChartsFigure.leftAxis.axisLineColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1) //y左軸の色(今回はy軸消すためにBGと同じ色にしている)
		iosChartsFigure.leftAxis.drawAxisLineEnabled = false //y左軸の表示(今回は表示しない)
		iosChartsFigure.leftAxis.labelCount = Int(10) //y軸ラベルの表示数
		iosChartsFigure.leftAxis.drawGridLinesEnabled = true //y軸のグリッド表示(今回は表示する)
		iosChartsFigure.leftAxis.gridColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) //y軸グリッドの色
		
		//その他UI設定
		iosChartsFigure.noDataFont = UIFont.systemFont(ofSize: 30) //Noデータ時の表示フォント
		iosChartsFigure.noDataTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) //Noデータ時の文字色
		iosChartsFigure.noDataText = "Keep Waiting" //Noデータ時に表示する文字
		iosChartsFigure.legend.enabled = false //"■ months"のlegendの表示
		iosChartsFigure.dragDecelerationEnabled = true //指を離してもスクロール続くか
		iosChartsFigure.dragDecelerationFrictionCoef = 0.6 //ドラッグ時の減速スピード(0-1)
		iosChartsFigure.chartDescription?.text = nil //Description(今回はなし)
		iosChartsFigure.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) //Background Color
		iosChartsFigure.animate(xAxisDuration: 1.2, yAxisDuration: 1.5, easingOption: .easeInOutElastic)//グラフのアニメーション(秒数で設定)
	}
	//グラフ描画部分
	func drawLineChart(_ values:  [String: [ChartDataEntry]]) {
		
		let data = LineChartData()
		
		////グラフのUI設定
		//グラフのグラデーション有効化
		let gradientColors = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor, #colorLiteral(red: 0.2196078449, green: 1, blue: 0.8549019694, alpha: 1).withAlphaComponent(0.3).cgColor] as CFArray // Colors of the gradient
		let colorLocations:[CGFloat] = [0.7, 0.0] // Positioning of the gradient
		let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
		
		let faceDirDataset = LineChartDataSet(entries: values["faceDir"], label: "face") //ds means DataSet
		faceDirDataset.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0) // Set the Gradient
		faceDirDataset.lineWidth = 1.0 //線の太さ
		faceDirDataset.circleRadius = 1.5 //プロットの大きさ
		faceDirDataset.drawCirclesEnabled = true //プロットの表示
		faceDirDataset.mode = .horizontalBezier
		faceDirDataset.fillAlpha = 0.8 //グラフの透過率(曲線は投下しない)
		faceDirDataset.drawFilledEnabled = false //グラフ下の部分塗りつぶし
		//ds.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) //グラフ塗りつぶし色
		faceDirDataset.drawValuesEnabled = true //各プロットのラベル表示
		faceDirDataset.highlightColor = #colorLiteral(red: 1, green: 0.8392156959, blue: 0.9764705896, alpha: 1) //各点を選択した時に表示されるx,yの線
		faceDirDataset.colors = [#colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)] //Drawing graph
		
		let eyeLeftDataset = LineChartDataSet(entries:values["eyeL"], label: "L")
		eyeLeftDataset.lineWidth = 1.0
		eyeLeftDataset.circleRadius = 1.5 //プロットの大きさ
		eyeLeftDataset.drawCirclesEnabled = true //プロットの表示
		eyeLeftDataset.mode = .horizontalBezier
		eyeLeftDataset.fillAlpha = 0.8
		eyeLeftDataset.drawFilledEnabled = false
		eyeLeftDataset.drawValuesEnabled = true //各プロットのラベル表示
		eyeLeftDataset.highlightColor = #colorLiteral(red: 1, green: 0.8392156959, blue: 0.9764705896, alpha: 1) //各点を選択した時に表示されるx,yの線
		eyeLeftDataset.colors = [#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)] //Drawing graph
		let eyeRightDataset =  LineChartDataSet(entries: values["eyeR"], label: "R")
		eyeRightDataset.lineWidth = 1.0
		eyeRightDataset.circleRadius = 1.5
		eyeRightDataset.drawCirclesEnabled = true
		eyeRightDataset.mode = .horizontalBezier
		eyeRightDataset.fillAlpha = 0.8
		eyeRightDataset.drawFilledEnabled = false
		eyeRightDataset.drawValuesEnabled = true
		eyeRightDataset.highlightColor = #colorLiteral(red: 1, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
		eyeRightDataset.colors = [#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)]
		
		data.addDataSet(faceDirDataset)
		data.addDataSet(eyeLeftDataset)
		data.addDataSet(eyeRightDataset)
		
		self.iosChartsFigure.data = data
	}
}
