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
    private var m_jsonWriter: JsonStreamWriter?
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
        guard let txtFile = getFileURL() else {
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
        guard let txtFile = getFileURL() else {
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
        guard let jsonFileURL = getFileURL() else {
            throw RecorderError.badURL
        }
        
        // attempt to set up file handle for writing
        do {
            try m_jsonWriter = JsonStreamWriter(url: jsonFileURL)
            try m_jsonWriter?.addKey("data")
            try m_jsonWriter?.startArray()
        }
        catch {
            throw RecorderError.cannotStartRecording
        }
        
        m_frameCount = 0
        
        // mark flag
        m_recording = true;
    }
    
    func stopRecording() {
        m_jsonWriter?.closeFile()
        m_recording = false
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if m_recording {
            let frameData = buildFrameData(frame: frame)
            try? m_jsonWriter?.addValue(frameData, newLineEntry: true, newLinesInParsedObject: false)
            m_frameCount += 1
        }
    }
    
    private func getFileURL() -> URL? {
        return getBasePath()?.appendingPathComponent("\(name).json", isDirectory: false)
    }
    
    private func buildFrameData(frame: ARFrame) -> DataEntryJsonSchema {
        // get camera transform for position and rotation data
        let transform = frame.camera.transform
        
        // calculate frame time
        var diff: Double = 0
        if let prev = m_previousTimestamp {
            diff = frame.timestamp - prev
        }
        m_previousTimestamp = frame.timestamp
        
        // build object
        return DataEntryJsonSchema(
            t: diff,
            px: transform.columns.3.x,
            py: transform.columns.3.y,
            pz: transform.columns.3.z,
            rx: transform.columns.0.x,
            ry: transform.columns.1.y,
            rz: transform.columns.2.z
        )
    }
}
