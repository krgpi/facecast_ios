import Foundation
import ARKit
import SceneKit
import SocketIO

class eyeGaze: NSObject, VirtualContentController { //Transmmit eyeGazes and Face direction
    
    var contentNode: SCNNode?
    var socket = SocketIOManager()
    let encoder = JSONEncoder()
    
    override init() {
        socket.establishConnection()
    }
    // Load multiple copies of the axis origin visualization for the transforms this class visualizes.
    lazy var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    lazy var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    var emitArray:[String: Float] = ["eyeL": 0.00, "eyeR": 0.00, "faceDir": 0.00]
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard let sceneView = renderer as? ARSCNView,
            anchor is ARFaceAnchor else { return nil }
        // Load an asset from the app bundle to provide visual content for the anchor.
        contentNode = SCNReferenceNode(named: "coordinateOrigin")
        
        // Add content for eye tracking in iOS 12.
        self.addEyeTransformNodes()
        
        socket.socketIOClient.emit("client_to_server_join", 1)
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
        leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
        emitArray["eyeL"] = faceAnchor.leftEyeTransform.columns.2.y
        emitArray["eyeR"] = faceAnchor.rightEyeTransform.columns.2.y
        emitArray["faceDir"] = faceAnchor.transform.columns.2.y
        
        do {
            let e = try JSONSerialization.data(withJSONObject: emitArray, options: .prettyPrinted)
            let str = String(bytes: e, encoding: .utf8)
            socket.socketIOClient.emit("chat message", str!)
        } catch  {
            print("err")
        }
    }
    
    func addEyeTransformNodes() {
        guard #available(iOS 12.0, *), let anchorNode = contentNode else { return }
        
        // Scale down the coordinate axis visualizations for eyes.
        rightEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        leftEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)
    }

}
