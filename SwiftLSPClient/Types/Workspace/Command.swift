//
//  Command.swift
//  SwiftLSPClient
//
//  Created by Zas G on 2021-09-02.
//  Copyright © 2021 Chime Systems. All rights reserved.
//

import Foundation
import AnyCodable

public struct ExecuteCommandParams: Codable {
    public let command: String
    public let arguments: [AnyCodable]?
    
    public init(command: Command) {
        self.command = command.command
        self.arguments = command.arguments
    }
    
    public init(command: String, arguments: [AnyCodable]?) {
        self.command = command
        self.arguments = arguments
    }
}

public typealias ExecuteCommandResponse = AnyCodable?

