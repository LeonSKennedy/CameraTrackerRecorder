//
//  JsonStreamWriterTest.swift
//  Camera Tracker RecorderTests
//
//  Created by Michael Levesque on 8/13/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import XCTest
@testable import Camera_Tracker_Recorder

class JsonStreamWriterTest: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func temporaryFileURL() -> URL {
        
        // Create a URL for an unique file in the system's temporary directory.
        let directory = NSTemporaryDirectory()
        let filename = UUID().uuidString
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        
        // Add a teardown block to delete any file at `fileURL`.
        addTeardownBlock {
            do {
                let fileManager = FileManager.default
                // Check that the file exists before trying to delete it.
                if fileManager.fileExists(atPath: fileURL.path) {
                    // Perform the deletion.
                    try fileManager.removeItem(at: fileURL)
                    // Verify that the file no longer exists after the deletion.
                    XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
                }
            } catch {
                // Treat any errors during file deletion as a test failure.
                XCTFail("Error while deleting temporary file: \(error)")
            }
        }
        
        // Return the temporary file URL for use in a test method.
        return fileURL
        
    }
    
    func performJsonTestFromData(_ data: TestJsonData) {
        let url = temporaryFileURL()
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        do {
            let writer = try JsonStreamWriter(url: url)
            for action in data.actions {
                switch action.action {
                case .StartObject:
                    try writer.startObject()
                case .EndObject:
                    try writer.endObject()
                case .StartArray:
                    try writer.startArray()
                case .EndArray:
                    try writer.endArray()
                case .AddKey:
                    try writer.addKey(action.value as! String)
                case .AddValue:
                    if action.value is String {
                        try writer.addValue(action.value as! String)
                    }
                    else if action.value is Bool {
                        try writer.addValue(action.value as! Bool)
                    }
                    else if action.value is Double {
                        try writer.addValue(action.value as! Double)
                    }
                    else if action.value is Float {
                        try writer.addValue(action.value as! Float)
                    }
                    else if action.value is Int {
                        try writer.addValue(action.value as! Int)
                    }
                }
            }
            writer.closeFile()
        }
        catch let error {
            if data.expectedError == nil {
                XCTFail("Unexpected error caught: \(error)")
            }
            else {
                return
            }
        }
        
        if data.expectedError == nil {
            validateJson(url: url, compareTo: data.result)
        }
        else {
            XCTFail("Expected error was not caught")
        }
    }
    
    func validateJson(url: URL, compareTo: String?) {
        do {
            // read file
            let fileHandle = try FileHandle(forReadingFrom: url)
            let data = fileHandle.readDataToEndOfFile()
            
            print(String(data: data, encoding: .utf8)!)
            
            // validate json
            let jsonObject = try JSONSerialization.jsonObject(
                with: data,
                options: JSONSerialization.ReadingOptions.mutableContainers)
            XCTAssertTrue(JSONSerialization.isValidJSONObject(jsonObject))
            
            // perform comparison test
            if let cmpTo = compareTo {
                let dataString = String(data: data, encoding: .utf8)!
                // remove whitespace from both
                let cmp1 = String(dataString.filter { !" \n\t\r".contains($0) })
                let cmp2 = String(cmpTo.filter { !" \n\t\r".contains($0) })
                XCTAssertEqual(cmp1, cmp2)
            }
        }
        catch let error{
            XCTFail("Failed with error: \(error)")
        }
    }
    
    func testJsonSuccessful() {
        performJsonTestFromData(testJsonData01)
        performJsonTestFromData(testJsonData02)
        performJsonTestFromData(testJsonData03)
        performJsonTestFromData(testJsonData04)
        performJsonTestFromData(testJsonData05)
    }
    
    func testJsonFailure() {
        performJsonTestFromData(testJsonBadData01)
        performJsonTestFromData(testJsonBadData02)
        performJsonTestFromData(testJsonBadData03)
        performJsonTestFromData(testJsonBadData04)
        performJsonTestFromData(testJsonBadData05)
        performJsonTestFromData(testJsonBadData06)
        performJsonTestFromData(testJsonBadData07)
        performJsonTestFromData(testJsonBadData08)
        performJsonTestFromData(testJsonBadData09)
        performJsonTestFromData(testJsonBadData10)
    }
    
}
