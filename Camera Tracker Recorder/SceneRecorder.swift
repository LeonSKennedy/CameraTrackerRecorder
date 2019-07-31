//
//  SceneRecorder.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 7/30/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
import ARKit

class SceneRecorder : NSObject, ARSessionDelegate {
    
    var recording: Bool
    var fileHandle: FileHandle?
    
    override init() {
        recording = false
        super.init()
    }
    
    func isRecording() -> Bool {
        return recording
    }
    
    func startRecording(filename: String) {
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths.first
        let fileURL = docsDir?.appendingPathComponent(filename)
        guard let url = fileURL else {
            print("Bad URL")
            return;
        }
        
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        
        do {
            try fileHandle = FileHandle(forWritingTo: url)
            guard fileHandle != nil else {
                print("file handle issue!!! \(url.absoluteString)")
                return;
            }
            
            recording = true;
        }
        catch {
            print(error)
        }
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if recording {
            let text: String = getTransformString(transform: frame.camera.transform)
            if let data = text.data(using: .utf8) {
                fileHandle?.write(data)
            }
        }
        //print("POSITION: \(frame.camera.transform.columns.3.debugDescription)")
    }
    
    func stopRecording() {
        if let handle = fileHandle {
            handle.closeFile();
        }
        recording = false
    }
    
    func getTransformString(transform: simd_float4x4) -> String {
        return """
        \(transform.columns.3.x),\(transform.columns.3.y),\(transform.columns.3.z),\
        \(transform.columns.0.x),\(transform.columns.1.y),\(transform.columns.2.z)\n
        """
    }
}
