import ARKit
import SceneKit
import SocketIO

class emotion: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?
    var socket = SocketIOManager()

    override init() {
        socket.establishConnection()
    }
    /// - Tag: CreateARSCNFaceGeometry
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let sceneView = renderer as? ARSCNView,
            anchor is ARFaceAnchor else { return nil }
        
        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else
        
        
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        let material = faceGeometry.firstMaterial!
        
        material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture") // Example texture map image.
        material.lightingModel = .physicallyBased
        
        contentNode = SCNNode(geometry: faceGeometry)
        socket.socketIOClient.emit("client_to_server_join", 0)
        #endif
        return contentNode
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)

        var blendShapes = faceAnchor.blendShapes
//        guard let jaw: NSNumber = blendShapes[ARFaceAnchor.BlendShapeLocation.jawOpen]
//            else { return }
        do {
            let e = try JSONSerialization.data(withJSONObject: blendShapes, options: .prettyPrinted)
            let str = String(bytes: e, encoding: .utf8)
            socket.socketIOClient.emit("chat message", str!)
        } catch  {
            print("err")
        }
    }

}

