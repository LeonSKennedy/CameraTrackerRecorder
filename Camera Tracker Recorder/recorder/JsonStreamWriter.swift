//
//  JsonStreamWriter.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 8/13/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation

enum JsonStreamWriterError: Error {
    case InitError(String)
    case ActionError(String)
    case BadKey(String)
    case DuplicateKey(String)
    case BadValue(String)
}

class JsonStreamWriter {
    enum EnclosureType {
        case Object
        case Array
        case Key
    }
    
    class Enclosure {
        let type: EnclosureType
        var count: Int
        var keys: Set<String>
        init(_ type: EnclosureType) {
            self.type = type
            keys = Set<String>()
            count = 0
        }
    }
    
    private let m_fileHandle: FileHandle
    private var m_enclosureStack: [Enclosure]
    private var m_level: Int
    private var m_reachedEnd: Bool
    
    init(url: URL) throws {
        do {
            try m_fileHandle = FileHandle(forWritingTo: url)
        }
        catch {
            throw JsonStreamWriterError.InitError("Can't initialize File Handle")
        }
        m_enclosureStack = []
        m_level = 0
        m_reachedEnd = false
        
        // start with open bracket
        try startObject()
    }
    
    deinit {
        closeFile()
    }
    
    func startObject(newLine: Bool? = nil) throws {
        // cannot start object at top level after finished
        guard !m_reachedEnd else {
            throw JsonStreamWriterError.ActionError("Cannot start new Object at top level")
        }
        
        // must not be at object level
        guard m_enclosureStack.last?.type != .Object else {
            throw JsonStreamWriterError.ActionError("Cannot start Object in Object level")
        }
        
        // write
        let prefix = getPrefix(
            delineate: true,
            newLine: newLine == nil ? m_enclosureStack.last?.type == .Key : newLine!
        )
        m_fileHandle.write("\(prefix){".data(using: .utf8)!)
        
        // add to stack
        pushEnclosureStack(type: .Object)
    }
    
    func endObject(newLine: Bool? = nil) throws {
        // must be at object level
        guard m_enclosureStack.last?.type == .Object else {
            throw JsonStreamWriterError.ActionError("Cannot end Object - Not at Object level")
        }
        
        // lower level
        m_level -= 1
        
        // write
        let prefix = getPrefix(
            delineate: false,
            newLine: newLine == nil ? m_enclosureStack.last!.count > 0 : newLine!
        )
        m_fileHandle.write("\(prefix)}".data(using: .utf8)!)
        
        // pop stack
        popEnclosureStack()
    }
    
    func startArray(newLine: Bool? = nil) throws {
        // cannot make an array at the top level
        guard !m_reachedEnd else {
            throw JsonStreamWriterError.ActionError("Cannot start Array at top level")
        }
        
        // we cannot be at an object level
        guard m_enclosureStack.last?.type != .Object else {
            throw JsonStreamWriterError.ActionError("Cannot start Array in Object level")
        }
        
        // write
        let prefix = getPrefix(
            delineate: true,
            newLine: newLine == nil ? m_enclosureStack.last?.type == .Key : newLine!
        )
        m_fileHandle.write("\(prefix)[".data(using: .utf8)!)
        
        // add to stack
        pushEnclosureStack(type: .Array)
    }
    
    func endArray(newLine: Bool? = nil) throws {
        // we must be in an array enclosure
        guard m_enclosureStack.last?.type == .Array else {
            throw JsonStreamWriterError.ActionError("Cannot end Array - Not at Array level")
        }
        
        // lower level
        m_level -= 1
        
        // write
        let prefix = getPrefix(
            delineate: false,
            newLine: newLine == nil ? m_enclosureStack.last!.count > 0 : newLine!
        )
        m_fileHandle.write("\(prefix)]".data(using: .utf8)!)
        
        // pop stack
        popEnclosureStack()
    }
    
    func addKey(_ key: String, newLine: Bool? = nil) throws {
        // can only make a key within an object
        guard m_enclosureStack.last?.type == .Object else {
            throw JsonStreamWriterError.ActionError("Cannot add Key - Not in Object level")
        }
        
        // make sure key is valid
        guard key.range(of:"^[a-zA-Z_][a-zA-Z_0-9]*$", options: .regularExpression) != nil else {
            throw JsonStreamWriterError.BadKey("Inavlid Json Key (\(key))")
        }
        
        // key must be unique
        guard !m_enclosureStack.last!.keys.contains(key) else {
            throw JsonStreamWriterError.DuplicateKey("Cannot add Key - Key already exists at this level")
        }
        
        // write
        let prefix = getPrefix(
            delineate: true,
            newLine: newLine == nil ? true : newLine!
        )
        m_fileHandle.write("\(prefix)\"\(key)\":".data(using: .utf8)!)
        
        // add key to set
        m_enclosureStack.last?.keys.insert(key)
        
        // add to stack
        pushEnclosureStack(type: .Key)
    }
    
    func addValue(_ value: Int, newLine: Bool? = nil) throws {
        try addValueInternal("\(value)", newLine: newLine)
    }
    
    func addValue(_ value: Float, newLine: Bool? = nil) throws {
        try addValueInternal("\(value)", newLine: newLine)
    }
    
    func addValue(_ value: Double, newLine: Bool? = nil) throws {
        try addValueInternal("\(value)", newLine: newLine)
    }
    
    func addValue(_ value: Bool, newLine: Bool? = nil) throws {
        try addValueInternal("\(value)", newLine: newLine)
    }
    
    func addValue(_ value: String, newLine: Bool? = nil) throws {
        try addValueInternal("\"\(value)\"", newLine: newLine)
    }
    
    func addValue<T>(_ value: T, newLine: Bool? = nil) throws where T:Encodable {
        var resultString: String
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(value)
            resultString = reformatEncodedValue(
                String(data: data, encoding: .utf8)!,
                newLine: newLine
            )
        }
        catch {
            throw JsonStreamWriterError.ActionError("Cannot add Value - Cannot Encode value: \(value)")
        }
        
        try addValueInternal(resultString, newLine: newLine)
    }
    
    func closeFile() {
        // close out levels
        while !m_enclosureStack.isEmpty {
            switch m_enclosureStack.last!.type {
            case .Key:
                try? startObject(newLine: false)
                try? endObject(newLine: false)
            case .Array:
                try? endArray()
            case .Object:
                try? endObject()
            }
        }
        m_fileHandle.closeFile()
    }
    
    private func reformatEncodedValue(_ value: String, newLine: Bool?) -> String {
        // if we want new lines, then we need to insert the correct amount of indentations
        if newLine == nil || newLine! == true {
            // separate by new lines
            let newLineSeparated = value.split(separator: "\n")
            return newLineSeparated.joined(
                separator: String(repeating: "\t", count: m_level))
        }
        else {
            return String(value.filter { !" \n\t\r".contains($0) })
        }
    }
    
    private func addValueInternal(_ value: String, newLine: Bool?) throws {
        // must not be in top level
        guard !m_enclosureStack.isEmpty else {
            throw JsonStreamWriterError.ActionError("Cannot add Value to top level")
        }
        
        // must not be in object level
        guard m_enclosureStack.last?.type != .Object else {
            throw JsonStreamWriterError.ActionError("Cannot add Value - Cannot be in Object level")
        }
        
        // write
        let prefix = getPrefix(
            delineate: true,
            newLine: newLine == nil ? m_enclosureStack.last?.type == EnclosureType.Array : newLine!
        )
        m_fileHandle.write("\(prefix)\(value)".data(using: .utf8)!)
        
        // close out key enclosure if we are in one
        performKeyClosure()
        
        // add to count
        addToCount()
    }
    
    private func getPrefix(delineate: Bool, newLine: Bool) -> String {
        let count = m_enclosureStack.last?.count ?? 0
        let comma = delineate && count > 0 ? "," : ""
        let whitespace = newLine ? "\n\(String(repeating: "\t", count: m_level))" : ""
        return "\(comma)\(whitespace)"
    }
    
    private func pushEnclosureStack(type: EnclosureType) {
        // add level for new enclosure, unless it is just a key
        if type != .Key {
            m_level += 1
        }
        
        // add to stack
        m_enclosureStack.append(Enclosure(type))
    }
    
    private func popEnclosureStack() {
        // pop from stack
        _ = m_enclosureStack.popLast()
        
        // if previous enclosure is a key, then we close that too
        performKeyClosure()
        
        // after a enclosure pop, we know that the new level we are at has one more to its count
        addToCount()
        
        // have we reached the end?
        m_reachedEnd = m_enclosureStack.isEmpty
    }
    
    private func performKeyClosure() {
        if m_enclosureStack.last?.type == EnclosureType.Key {
            _ = m_enclosureStack.popLast()
        }
    }
    
    private func addToCount() {
        m_enclosureStack.last?.count += 1
    }
}
