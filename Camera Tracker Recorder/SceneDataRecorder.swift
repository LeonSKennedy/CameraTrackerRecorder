//
//  SceneDataRecorder.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 8/4/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
import ARKit

final class SceneDataRecorder : NSObject, SceneRecorder, ARSessionDelegate {
    private let m_name: String
    private var m_prepared: Bool
    private var m_recording: Bool
    private var m_fileHandle: FileHandle?
    
    var isPrepared: Bool { get { return m_prepared } }
    var isRecording: Bool { get { return m_recording } }
    var name: String { get { return m_name } }
    
    init(name: String, arSession:ARSession) throws {
        m_name = name
        m_prepared = false
        m_recording = false
        super.init()
        arSession.delegate = self
    }
    
    deinit {
        stopRecording()
    }
    
    func getBasePath() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func doesFileExist() -> Bool {
        guard let txtFile = getFile() else {
            return false
        }
        return FileManager.default.fileExists(atPath: txtFile.path)
    }
    
    func prepareRecording() throws {
        // don't prepare if already prepared
        guard !isPrepared else {
            return
        }
        
        // grab file location
        guard let txtFile = getFile() else {
            throw RecorderError.badURL
        }
        
        // create text file
        guard FileManager.default.createFile(atPath: txtFile.path, contents: nil, attributes: nil) else {
            throw RecorderError.cannotCreateFile
        }
        
        // mark flag
        m_prepared = true
    }
    
    func startRecording() throws {
        // Do nothing if recording has already started
        guard !isRecording else {
            return
        }
        
        // if not prepared, then prepare it
        if !isPrepared {
            try prepareRecording()
        }
        
        // get file location for data file
        guard let txtFile = getFile() else {
            throw RecorderError.badURL
        }
        
        // attempt to set up file handle for writing
        do {
            try m_fileHandle = FileHandle(forWritingTo: txtFile)
            guard m_fileHandle != nil else {
                throw RecorderError.cannotStartRecording
            }
        }
        catch {
            throw RecorderError.cannotStartRecording
        }
        
        // mark flag
        m_recording = true;
    }
    
    func stopRecording() {
        if let handle = m_fileHandle {
            handle.closeFile();
        }
        m_recording = false
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if m_recording {
            let text: String = getDataEntryString(transform: frame.camera.transform)
            if let data = text.data(using: .utf8) {
                m_fileHandle?.write(data)
            }
        }
    }
    
    private func getFile() -> URL? {
        return getBasePath()?.appendingPathComponent("\(name).txt", isDirectory: false)
    }
    
    private func getDataEntryString(transform: simd_float4x4) -> String {
        return """
        \(transform.columns.3.x),\(transform.columns.3.y),\(transform.columns.3.z),\
        \(transform.columns.0.x),\(transform.columns.1.y),\(transform.columns.2.z)\n
        """
    }
}
