/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import SceneKit
import UIKit
import SocketIO

class receiveViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var currentFaceAnchor: ARFaceAnchor?
    
    var socket = SocketIOManager()
    var top: NSDictionary!
    var blendArray: [ARFaceAnchor.BlendShapeLocation: NSNumber]!
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        socket.socketIOClient.on("chat message"){data,ack in
            print("received!!")
            guard let cur = data[0] as? String else {
                print(data)
                return }
            print(data)
            let orgdata: Data = cur.data(using: String.Encoding.utf8)!
            do {
                let json = try JSONSerialization.jsonObject(with: orgdata, options: JSONSerialization.ReadingOptions.allowFragments)
                self.top = json as! NSDictionary
                self.blendArray = self.top as! [ARFaceAnchor.BlendShapeLocation : NSNumber]
            } catch {
                print(error)
            }
        }
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene.background.contents = UIColor.lightGray
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let faceGeometry = ARSCNFaceGeometry.init(device: sceneView.device!)!
        let material = faceGeometry.firstMaterial!
        
        material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture") // Example texture map image.
        material.lightingModel = .physicallyBased
        let contentNode = SCNNode.init(geometry: faceGeometry)
        let position = SCNVector3(x: 0.0, y: 0.0, z: -0.5)
        if let camera = sceneView.pointOfView{
            contentNode.position = camera.convertPosition(position, to: nil)
        }
        self.sceneView.scene.rootNode.addChildNode(contentNode)
        
        socket.socketIOClient.connect()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        socket.socketIOClient.emit("client_to_server_join", 0)
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        socket.closeConnection()
    }
    
    // MARK: - ARSessionDelegate
    
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

