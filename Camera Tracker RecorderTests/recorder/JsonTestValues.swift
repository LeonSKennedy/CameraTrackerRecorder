//
//  JsonTestValues.swift
//  Camera Tracker RecorderTests
//
//  Created by Michael Levesque on 8/13/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import Foundation
@testable import Camera_Tracker_Recorder

enum JsonTestAction {
    case StartObject
    case EndObject
    case StartArray
    case EndArray
    case AddKey
    case AddValue
}

struct EncodeEmpty: Encodable {}

struct TestEncodeObject: Encodable {
    let testValue1: Int
    let testValue2: Float
    let testValue3: String
    let testValue4: Double
    let testValue5: Bool
}

struct TestJsonData {
    let actions: [(action:JsonTestAction, value:Any?)]
    let expectedError: JsonStreamWriterError?
    let result: String?
}

let testJsonData01 = TestJsonData(
    actions: [],
    expectedError: nil,
    result: """
    {}
    """
)

let testJsonData02 = TestJsonData(
    actions: [
        (.AddKey, "intKey"),
        (.AddValue, 123),
        (.AddKey, "boolKey"),
        (.AddValue, true),
        (.AddKey, "stringKey"),
        (.AddValue, "string"),
        (.AddKey, "floatKey"),
        (.AddValue, -0.567)
    ],
    expectedError: nil,
    result: """
    {
        "intKey":123,
        "boolKey":true,
        "stringKey":"string",
        "floatKey":-0.567
    }
    """
)

let testJsonData03 = TestJsonData(
    actions: [
        (.AddKey, "arrayKey"),
        (.StartArray, nil),
        (.AddValue, 1),
        (.AddValue, 2),
        (.AddValue, 3),
        (.AddValue, 4),
        (.AddValue, 5)
    ],
    expectedError: nil,
    result: """
    {
        "arrayKey":[1,2,3,4,5]
    }
    """
)

let testJsonData04 = TestJsonData(
    actions: [
        (.AddKey, "arrayKey"),
        (.StartArray, nil),
        (.StartObject, nil),
        (.EndObject, nil),
        (.StartObject, nil),
        (.AddKey, "testKey"),
        (.AddValue, 123),
        (.AddKey, "testKey2"),
        (.AddValue, 456),
        (.EndObject, nil),
        (.EndArray, nil)
    ],
    expectedError: nil,
    result: """
    {
        "arrayKey":[
            {},
            {
                "testKey":123,
                "testKey2":456
            }
        ]
    }
    """
)

let testJsonData05 = TestJsonData(
    actions: [
        (.AddKey, "objKey"),
        (.StartObject, nil),
        (.AddKey, "valKey"),
        (.AddValue, 123),
        (.EndObject, nil),
        (.AddKey, "arrKey"),
        (.StartArray, nil),
        (.AddValue, 1),
        (.AddValue, 2),
        (.EndArray, nil)
    ],
    expectedError: nil,
    result: """
    {
        "objKey":{
            "valKey":123
        },
        "arrKey":[
            1,
            2
        ]
    }
    """
)


let testJsonBadData01 = TestJsonData(
    actions: [
        (.AddValue, "badValue"),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData02 = TestJsonData(
    actions: [
        (.AddKey, "key1"),
        (.AddKey, "key2"),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData03 = TestJsonData(
    actions: [
        (.AddKey, "key1"),
        (.StartObject, nil),
        (.AddKey, "key2"),
        (.EndObject, nil)
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData04 = TestJsonData(
    actions: [
        (.AddKey, "key"),
        (.AddValue, "value"),
        (.AddKey, "key"),
        (.AddValue, "value"),
    ],
    expectedError: .DuplicateKey(""),
    result: nil
)

let testJsonBadData05 = TestJsonData(
    actions: [
        (.AddKey, "key"),
        (.StartObject, nil),
        (.EndArray, nil),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData06 = TestJsonData(
    actions: [
        (.AddKey, "key"),
        (.StartArray, nil),
        (.EndObject, nil),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData07 = TestJsonData(
    actions: [
        (.StartArray, nil),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData08 = TestJsonData(
    actions: [
        (.StartObject, nil),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData09 = TestJsonData(
    actions: [
        (.AddKey, "objKey"),
        (.StartObject, nil),
        (.EndObject, nil),
        (.EndObject, nil),
        (.EndObject, nil),
    ],
    expectedError: .ActionError(""),
    result: nil
)

let testJsonBadData10 = TestJsonData(
    actions: [
        (.AddKey, "objKey"),
        (.StartObject, nil),
        (.EndObject, nil),
        (.EndObject, nil),
        (.StartObject, nil)
    ],
    expectedError: .ActionError(""),
    result: nil
)
