//
//  AsyncGaiaDeviceVendorExtension.swift
//  SDK Dev
//
//  Created by Hozefa Indorewala on 12.11.25.
//  Copyright © 2025 Mimi Hearing Technologies GmbH. All rights reserved.
//

import GaiaCore
import Foundation
import GaiaBase
import Packets
import GaiaLogger

actor AsyncGaiaV3DeviceVendorExtension: @preconcurrency GaiaDeviceVendorExtensionProtocol {

    nonisolated(unsafe) static var vendorID: UInt16 = 0x0000 // Overriden in init

    // MARK: - Properties

    private let connection: GaiaDeviceConnectionProtocol
    private weak var device: GaiaDeviceProtocol?
    private let notificationCenter: NotificationCenter
    private let featureID: UInt8
    private let name: String

    // MARK: - Async Stream Support

    /// Stream for receiving notifications from the device
    nonisolated(unsafe) private var notificationContinuation: AsyncStream<(notificationID: UInt8, data: Data)>.Continuation?
    let notifications: AsyncStream<(notificationID: UInt8, data: Data)>

    /// Stream for receiving errors
    nonisolated(unsafe) private var errorContinuation: AsyncStream<GaiaError>.Continuation?
    let errors: AsyncStream<GaiaError>

    // MARK: - Command Response Management

    /// Tracks pending command continuations by command ID
    private var pendingCommands: [UInt16: CheckedContinuation<Data, Error>] = [:]

    // MARK: - Initialization

    init(vendorID: UInt16,
         featureID: UInt8,
         name: String,
         device: any GaiaDeviceProtocol,
         connection: any GaiaDeviceConnectionProtocol,
         notificationCenter: NotificationCenter) {
        Self.vendorID = vendorID
        self.featureID = featureID
        self.name = name
        self.device = device
        self.connection = connection
        self.notificationCenter = notificationCenter

        // Initialize notification stream
        var notificationCont: AsyncStream<(notificationID: UInt8, data: Data)>.Continuation?
        self.notifications = AsyncStream { continuation in
            notificationCont = continuation
        }
        self.notificationContinuation = notificationCont

        // Initialize error stream
        var errorCont: AsyncStream<GaiaError>.Continuation?
        self.errors = AsyncStream { continuation in
            errorCont = continuation
        }
        self.errorContinuation = errorCont
    }

    init(device: any GaiaDeviceProtocol, connection: any GaiaDeviceConnectionProtocol, notificationCenter: NotificationCenter) {
        fatalError("Use init(vendorID:featureID:device:connection:notificationCenter:) instead")
    }

    // MARK: - Lifecycle Methods

    func start() {
        // Extension started - perform any initialization here
        LOG(.low, "\(name) started")
    }

    func stop() {
        // Clean up resources and cancel pending operations
        notificationContinuation?.finish()
        errorContinuation?.finish()

        // Cancel all pending commands
        for (_, continuation) in pendingCommands {
            continuation.resume(throwing: CancellationError())
        }
        pendingCommands.removeAll()

        LOG(.low, "\(name) stopped")
    }

    // MARK: - Data Reception (Protocol Requirement)

    func dataReceived(_ data: Data) -> Bool {
        guard let message = GaiaV3GATTPacket(data: data),
              message.vendorID == Self.vendorID else {
            return true
        }

        switch message.messageDescription {
        case .notification(notificationID: let notificationID, data: let data):
            // Send notification through the async stream
            notificationContinuation?.yield((notificationID, data))
            return false // Notifications don't need acknowledgement tracking

        case .response(command: let command, data: let data):
            // Resume the continuation waiting for this command response
            if let continuation = pendingCommands.removeValue(forKey: command) {
                continuation.resume(returning: data)
            }
            return true // Response received for acknowledged command

        case .error(command: let command, errorCode: let errorCode, data: let data):
            // Resume with error for pending command
            if let continuation = pendingCommands.removeValue(forKey: command) {
                let error = GaiaCommandError(command: command, errorCode: errorCode, data: data)
                continuation.resume(throwing: error)
            }
            return true // Error response received for acknowledged command

        case .unknown:
            LOG(.high, "\(name) unknown message received")
            return true
        }
    }

    func didError(_ error: GaiaBase.GaiaError) {
        // Send error through the async stream
        errorContinuation?.yield(error)
    }

    // MARK: - Async Command Methods

    /// Sends a command and waits for the response asynchronously
    /// - Parameters:
    ///   - commandID: The command identifier
    ///   - payload: Optional data payload
    /// - Returns: Response data from the device
    /// - Throws: Error if the command fails or times out
    func sendCommand(commandID: UInt16, payload: Data = Data()) async throws -> Data {
        let message = GaiaV3GATTPacket(
            vendorID: Self.vendorID,
            featureID: featureID,
            commandID: commandID,
            payload: payload
        )

        return try await withCheckedThrowingContinuation { continuation in
            // Cancel any existing continuation for this command
            if let existingContinuation = pendingCommands[commandID] {
                existingContinuation.resume(throwing: CancellationError())
                LOG(.high, "\(name) cancelled pending command \(commandID)")
            }
            
            // Store the continuation for this command
            pendingCommands[commandID] = continuation

            // Send the command through the connection
            connection.sendData(
                channel: .command,
                payload: message.data,
                acknowledgementExpected: true
            )
        }
    }
}

// MARK: - Error Types

/// Error thrown when a command receives an error response
struct GaiaCommandError: Error, CustomStringConvertible {
    let command: UInt16
    let errorCode: UInt8
    let data: Data

    var description: String {
        "GAIA Command:\(command) failed with error code:\(errorCode)"
    }
}
