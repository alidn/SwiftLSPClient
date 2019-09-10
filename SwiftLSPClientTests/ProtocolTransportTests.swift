//
//  ProtocolTransportTests.swift
//  SwiftLSPClientTests
//
//  Created by Matt Massicotte on 2019-02-07.
//  Copyright © 2019 Chime Systems. All rights reserved.
//

import XCTest
@testable import SwiftLSPClient

class ProtocolTransportTests: XCTestCase {
    typealias TestResult = Result<JSONRPCResultResponse<TextDocumentIdentifier>, ProtocolTransportError>

    func testSendRequest() {
        let dataTransport = MockDataTransport()
        let messageTransport = MessageTransport(dataTransport: dataTransport)
        let transport = ProtocolTransport(messageTransport: messageTransport)

        let expectation = XCTestExpectation(description: "Response Message")

        let request = TextDocumentIdentifier(uri: "hello")
        transport.sendRequest(request, method: "mymethod") { (result: TestResult) in
            let value = try? result.get()
            XCTAssertEqual(value?.result, TextDocumentIdentifier(uri: "goodbye"))

            expectation.fulfill()
        }

        dataTransport.mockRead("Content-Length: 51\r\n\r\n")
        dataTransport.mockRead("""
{"jsonrpc":"2.0","id":1,"result":{"uri":"goodbye"}}
""")

        wait(for: [expectation], timeout: 1.0)
    }

    func testSendNotification() {
        let dataTransport = MockDataTransport()
        let messageTransport = MessageTransport(dataTransport: dataTransport)
        let transport = ProtocolTransport(messageTransport: messageTransport)

        let expectation = XCTestExpectation(description: "Notification Message")

        let request = TextDocumentIdentifier(uri: "hello")

        transport.sendNotification(request, method: "mynotification") { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        let result = "Content-Length: 68\r\n\r\n{\"jsonrpc\":\"2.0\",\"method\":\"mynotification\",\"params\":{\"uri\":\"hello\"}}"

        let writtenStrings = dataTransport.writtenData.compactMap({ String(data: $0, encoding: .utf8) })

        XCTAssertEqual(writtenStrings, [result])
    }

    func testServerToClientNotification() {
        let dataTransport = MockDataTransport()
        let messageTransport = MessageTransport(dataTransport: dataTransport)
        let transport = ProtocolTransport(messageTransport: messageTransport)
        let transportDelegate = MockProtocolTransportDelegate()

        transport.delegate = transportDelegate

        let expectation = XCTestExpectation(description: "Notification Message")

        transportDelegate.notificationHandler = { (method, data) in
            XCTAssertEqual(method, "iamnotification")

            let result = try? JSONDecoder().decode(JSONRPCNotificationParams<String>.self, from: data)

            XCTAssertEqual(result?.params, "iamstring")
            expectation.fulfill()
        }

        dataTransport.mockRead("Content-Length: 65\r\n\r\n")
        dataTransport.mockRead("""
{"jsonrpc":"2.0","method":"iamnotification","params":"iamstring"}
""")

        wait(for: [expectation], timeout: 1.0)
    }
}