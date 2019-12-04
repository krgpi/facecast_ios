//
//  emotion.swift
//
//  Created by y.k. noaki on 2019/01/31.
//

import ARKit
import SceneKit

class emotion: NSObject, VirtualContentController {
	
	var contentNode: SCNNode?
	
	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		guard let sceneView = renderer as? ARSCNView,
			anchor is ARFaceAnchor else { return nil }
		
		let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
		let material = faceGeometry.firstMaterial!
		
		material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture") // Example texture map image.
		material.lightingModel = .physicallyBased
		
		contentNode = SCNNode(geometry: faceGeometry)
		return contentNode
	}

	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
			let faceAnchor = anchor as? ARFaceAnchor
			else { return }
		
		faceGeometry.update(from: faceAnchor.geometry)
	}

}
