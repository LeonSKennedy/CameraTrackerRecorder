//
//  SceneAudioRecorderDecorator.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 8/4/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
import AVFoundation

class SceneAudioRecorderDecorator: SceneRecorder {
    private let m_sceneRecorder: SceneRecorder
    
    private var m_audioHandle: AVAudioRecorder?
    
    var isPrepared: Bool { get {return m_sceneRecorder.isPrepared}}
    var isRecording: Bool { get {return m_sceneRecorder.isRecording}}
    var name: String { get {return m_sceneRecorder.name}}
    
    init(sceneRecorder: SceneRecorder) throws {
        self.m_sceneRecorder = sceneRecorder
    }
    
    deinit {
        stopRecording()
    }
    
    func getBasePath() -> URL? {
        return m_sceneRecorder.getBasePath()
    }
    
    func doesFileExist() -> Bool {
        return m_sceneRecorder.doesFileExist()
    }
    
    func prepareRecording() throws {
        // don't prepare if already prepared
        guard !isPrepared else {
            return
        }
        
        // create audio file
        guard let audioFile = getBasePath()?.appendingPathComponent("\(name).m4a", isDirectory: false) else {
            throw RecorderError.badURL
        }
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
        guard let successful = m_audioHandle?.prepareToRecord() else {
            throw RecorderError.cannotCreateFile
        }
        guard successful else {
            throw RecorderError.cannotCreateFile
        }
        
        // prepare other
        try m_sceneRecorder.prepareRecording()
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
        
        // start recording audio
        guard let successful = m_audioHandle?.record() else {
            throw RecorderError.cannotStartRecording
        }
        guard successful else {
            throw RecorderError.cannotStartRecording
        }
        
        // start recording other
        try m_sceneRecorder.startRecording()
    }
    
    func stopRecording() {
        m_audioHandle?.stop()
        m_sceneRecorder.stopRecording()
    }
}
