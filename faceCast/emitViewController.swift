//
//  emitViewController.swift
//  emit blendshapes array to socket connection.
//
//  Created by y.k. noaki on 2019/01/31.
//

import ARKit
import SceneKit
import UIKit
//import SocketIO

class emitViewController: UIViewController {

	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet weak var tabBar: UITabBar!
	@IBOutlet weak var debugLabelView: UILabel!
	
//	var socket = SocketIOManager()
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
		tabBar.selectedItem = tabBar.items!.first!
		selectedVirtualContent = VirtualContentType(rawValue: tabBar.selectedItem!.tag)
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
		emitArray["eyeL"] = round(asin(faceAnchor.leftEyeTransform.columns.2.x))
		emitArray["eyeR"] = round(asin(faceAnchor.rightEyeTransform.columns.2.x))
		emitArray["faceDir"] = round(asin(faceAnchor.transform.columns.2.x))
		print(emitArray)
		DispatchQueue.main.async {
			self.debugLabelView.text = "L: \(self.emitArray["eyeL"]),R: \(self.emitArray["eyeR"]),face: \(self.emitArray["faceDir"])"
		}
		do {
			let e = try JSONSerialization.data(withJSONObject: emitArray, options: .prettyPrinted)
			let str = String(bytes: e, encoding: .utf8)
//			socket.socketIOClient.emit("chat message", str!)
		} catch  {
			print("err")
		}
		selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
	}
}

