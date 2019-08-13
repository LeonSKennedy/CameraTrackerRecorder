//
//  SceneDataRecorder.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 8/4/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
import ARKit



struct SceneFrameData {
    var frameTime: Double
    var pos: (x: Float, y: Float, z: Float)
    var rot: (x: Float, y: Float, z: Float)
    
    func toString() -> String {
        return """
        {\"t\":\(frameTime),\
        \"px\":\(pos.x),\"py\":\(pos.y),\"pz\":\(pos.z),\
        \"rx\":\(rot.x),\"ry\":\(rot.y),\"rz\":\(rot.z)}
        """
    }
}

final class SceneDataRecorder : NSObject, SceneRecorder, ARSessionDelegate {
    private let m_name: String
    private var m_prepared: Bool
    private var m_recording: Bool
    private var m_fileHandle: FileHandle?
    private var m_previousTimestamp: Double?
    private var m_frameCount: Int
    
    var isPrepared: Bool { get { return m_prepared } }
    var isRecording: Bool { get { return m_recording } }
    var name: String { get { return m_name } }
    
    init(name: String, arSession:ARSession) throws {
        m_name = name
        m_prepared = false
        m_recording = false
        m_frameCount = 0
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
        
        m_frameCount = 0
        writeStartingJson()
        
        // mark flag
        m_recording = true;
    }
    
    func stopRecording() {
        if m_recording {
            writeEndingJson()
        }
        if let handle = m_fileHandle {
            handle.closeFile();
        }
        m_recording = false
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if m_recording {
            let frameData = buildFrameData(frame: frame)
            let prefix = m_frameCount == 0 ? "\t\t" : ",\n\t\t"
            let s = "\(prefix)\(frameData.toString())"
            if let dataToWrite = s.data(using: .utf8) {
                m_fileHandle?.write(dataToWrite)
            }
            m_frameCount += 1
        }
    }
    
    private func getFile() -> URL? {
        return getBasePath()?.appendingPathComponent("\(name).json", isDirectory: false)
    }
    
    private func buildFrameData(frame: ARFrame) -> SceneFrameData {
        // get camera transform for position and rotation data
        let transform = frame.camera.transform
        
        // calculate frame time
        var diff: Double = 0
        if let prev = m_previousTimestamp {
            diff = frame.timestamp - prev
        }
        m_previousTimestamp = frame.timestamp
        
        // build object
        return SceneFrameData(
            frameTime: diff,
            pos: (x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z),
            rot: (x: transform.columns.0.x, y: transform.columns.1.y, z: transform.columns.2.z)
        )
    }
    
    private func writeStartingJson() {
        let s = """
        {
        \t\"data\":[\n
        """
        if let dataToWrite = s.data(using: .utf8) {
            m_fileHandle?.write(dataToWrite)
        }
    }
    
    private func writeEndingJson() {
        let s = """
        \n\t]
        }
        """
        if let dataToWrite = s.data(using: .utf8) {
            m_fileHandle?.write(dataToWrite)
        }
    }
}
