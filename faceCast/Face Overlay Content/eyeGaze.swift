//
//  eyeGaze.swift
//
//  Created by y.k. noaki on 2019/01/31.
//

import ARKit
import SceneKit

class eyeGaze: NSObject, VirtualContentController {
	
	var contentNode: SCNNode?
	
	lazy var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
	lazy var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		
		guard anchor is ARFaceAnchor else { return nil }
		contentNode = SCNReferenceNode(named: "coordinateOrigin")
		
		// Add content for eye tracking in iOS 12.
		self.addEyeTransformNodes()
		
		// Provide the node to ARKit for keeping in sync with the face anchor.
		return contentNode
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let faceAnchor = anchor as? ARFaceAnchor
			else { return }
		
		rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
		leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
	}
	
	func addEyeTransformNodes() {
		guard let anchorNode = contentNode else { return }
		
		// Scale down the coordinate axis visualizations for eyes.
		rightEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
		leftEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
		
		anchorNode.addChildNode(rightEyeNode)
		anchorNode.addChildNode(leftEyeNode)
	}

}
