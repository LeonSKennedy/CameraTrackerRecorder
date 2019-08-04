//
//  ViewController.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 7/2/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var recButton: UIButton!
    
    var sceneRecorder: SceneRecorder?
    var useAudio: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show tracking points
        sceneView.debugOptions = SCNDebugOptions.showFeaturePoints
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // Set the scene to the view
        sceneView.scene = scene
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    self.useAudio = allowed
                    self.createRecorder()
                }
            }
        } catch {
            useAudio = false
            createRecorder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    @IBAction func onRecordTouchUp(_ sender: Any) {
        let isRecording: Bool = sceneRecorder?.isRecording ?? false
        
        do {
            if isRecording {
                sceneRecorder?.stopRecording()
                createRecorder()
            }
            else {
                try sceneRecorder?.startRecording()
            }
        }
        catch {
            print(error)
        }
        
        updateRecordButton()
    }
    
    private func createRecorder() {
        do {
            try sceneRecorder = SceneRecorder(name: "test", useAudio: useAudio)
            sceneView.session.delegate = sceneRecorder
        }
        catch {
            print(error)
        }
    }
    
    private func updateRecordButton() {
        let isRecording: Bool = sceneRecorder?.isRecording ?? false
        if isRecording {
            recButton.backgroundColor = UIColor.gray
            recButton.setTitle("Stop", for: UIControl.State.normal)
        }
        else {
            recButton.backgroundColor = UIColor.red
            recButton.setTitle("Record", for: UIControl.State.normal)
        }
    }
}
