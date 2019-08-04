//
//  SceneRecorder.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 7/30/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
import ARKit

enum RecorderError: Error {
    case badURL
    case badName
    case cannotCreateFile
    case cannotStartRecording
}

class SceneRecorder : NSObject, ARSessionDelegate {
    
    private let m_txtFileURL: URL?
    private let m_audioFileURL: URL?
    private let m_useAudio: Bool
    private var m_prepared: Bool
    private var m_recording: Bool
    private var m_fileHandle: FileHandle?
    private var m_audioHandle: AVAudioRecorder?
    
    var isPrepared: Bool { get { return m_prepared } }
    var isRecording: Bool { get { return m_recording } }
    
    init(name: String, useAudio: Bool) throws {
        // setup URL location for file
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = dirPaths.first
        m_useAudio = useAudio
        
        // if for some reason we can't get the directory, then throw an error
        guard docsDir != nil else {
            throw RecorderError.badURL
        }
        
        // build URL for recording files
        m_txtFileURL = docsDir?.appendingPathComponent("\(name).txt", isDirectory: false)
        guard m_txtFileURL != nil else {
            throw RecorderError.badName
        }
        if m_useAudio {
            m_audioFileURL = docsDir?.appendingPathComponent("\(name).m4a", isDirectory: false)
            guard m_audioFileURL != nil else {
                throw RecorderError.badName
            }
        }
        else {
            m_audioFileURL = nil
        }
        
        // initialize flags
        m_prepared = false
        m_recording = false
        super.init()
    }
    
    deinit {
        stopRecording()
    }
    
    func filesExists() -> Bool {
        guard let txtFile = m_txtFileURL else {
            return false;
        }
        return FileManager.default.fileExists(atPath: txtFile.path)
    }
    
    func prepareRecording() throws {
        // don't prepare if already prepared
        guard !m_prepared else {
            return
        }
        
        // grab file location
        guard let txtFile = m_txtFileURL, let audioFile = m_audioFileURL else {
            throw RecorderError.badURL
        }
        
        // create text file
        guard FileManager.default.createFile(atPath: txtFile.path, contents: nil, attributes: nil) else {
            throw RecorderError.cannotCreateFile
        }
        
        // create audio file
        if m_useAudio {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            do {
                try m_audioHandle = AVAudioRecorder(url: audioFile, settings: settings)
            }
            catch {
                throw RecorderError.cannotCreateFile
            }
            guard m_audioHandle != nil else {
                throw RecorderError.cannotCreateFile
            }
            m_audioHandle?.prepareToRecord()
        }
        
        // mark flag
        m_prepared = true
    }
    
    func startRecording() throws {
        // Do nothing if recording has already started
        guard !m_recording else {
            return
        }
        
        // if not prepared, then prepare it
        if !m_prepared {
            try prepareRecording()
        }
        
        // get file location for data file
        guard let dataFile = m_txtFileURL else {
            throw RecorderError.badURL
        }
        
        // attempt to set up file handle for writing
        do {
            try m_fileHandle = FileHandle(forWritingTo: dataFile)
            guard m_fileHandle != nil else {
                throw RecorderError.cannotStartRecording
            }
        }
        catch {
            throw RecorderError.cannotStartRecording
        }
        
        // begin audio recording
        if m_useAudio {
            guard let audioHandle = m_audioHandle else {
                throw RecorderError.cannotStartRecording
            }
            guard audioHandle.record() else {
                throw RecorderError.cannotStartRecording
            }
        }
        
        // mark flag
        m_recording = true;
    }
    
    func stopRecording() {
        m_recording = false
        if let handle = m_fileHandle {
            handle.closeFile();
        }
        if let handle = m_audioHandle {
            handle.stop()
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if m_recording {
            let text: String = getDataEntryString(transform: frame.camera.transform)
            if let data = text.data(using: .utf8) {
                m_fileHandle?.write(data)
            }
        }
    }
    
    private func getDataEntryString(transform: simd_float4x4) -> String {
        return """
        \(transform.columns.3.x),\(transform.columns.3.y),\(transform.columns.3.z),\
        \(transform.columns.0.x),\(transform.columns.1.y),\(transform.columns.2.z)\n
        """
    }
}
