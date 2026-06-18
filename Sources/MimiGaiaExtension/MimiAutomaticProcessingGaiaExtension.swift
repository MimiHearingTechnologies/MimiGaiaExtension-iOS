// ⚠️ GENERATED — do not edit. Synced from MimiFirmwareKit-Swift@4197f58.

//
//  MimiAutomaticProcessingGaiaExtension.swift
//  MimiGaiaExtension
//
//  Created by Hozefa Indorewala on 29.10.25.
//  Copyright © 2025 QTI. All rights reserved.
//

import Foundation
import GaiaCore
import GaiaBase
import Packets
import GaiaLogger

enum MimiGaiaCommand: UInt16 {
    case protobufRequestMsgChunk = 1
    case protobufRequestMsgEnd = 2
    case protobufResponseMsgChunk = 3
    case protobufResponseMsgEnd = 4
}

/// Errors that can occur when communicating with Mimi-enabled devices.
public enum MimiGaiaError: Error {
    /// The data provided for transmission is empty.
    ///
    /// This error is thrown when attempting to send an empty `Data` object to the device,
    /// which would result in no chunks being transmitted.
    case emptyData
}

public actor MimiAutomaticProcessingGaiaExtension {

    private struct Defaults {
        static let vendorID: UInt16 = 0x4AAA
        static let featureID: UInt8 = 0x20
        static let maxChunkSize: Int = 96 // bytes
    }

    public nonisolated var gaiaExtension: GaiaDeviceVendorExtensionProtocol {
        _gaiaExtension
    }
    nonisolated let _gaiaExtension: AsyncGaiaV3DeviceVendorExtension

    public init(device: any GaiaDeviceProtocol,
                connection: any GaiaDeviceConnectionProtocol,
                notificationCenter: NotificationCenter) {
        nonisolated(unsafe) let unsafeDevice = device
        nonisolated(unsafe) let unsafeConnection = connection
        self._gaiaExtension = AsyncGaiaV3DeviceVendorExtension(vendorID: Defaults.vendorID, featureID: Defaults.featureID, name: "MimiAutomaticProcessingGaiaExtension", device: unsafeDevice, connection: unsafeConnection, notificationCenter: notificationCenter)
    }

    public func send(_ data: Data) async throws -> Data {
        let chunks = data.chunked(size: Defaults.maxChunkSize)

        guard !chunks.isEmpty else {
            throw MimiGaiaError.emptyData
        }

        let numberOfResponseChunks = try await sendRequestChunks(chunks)
        let responseData = try await receiveResponseChunks(count: numberOfResponseChunks)

        return responseData
    }

    private func sendRequestChunks(_ chunks: [Data]) async throws -> Int {
        var mutableChunks = chunks
        let lastChunk = mutableChunks.removeLast()

        // Send all chunks except the last one
        for chunk in mutableChunks {
            _ = try await _gaiaExtension.sendCommand(commandID: MimiGaiaCommand.protobufRequestMsgChunk.rawValue, payload: chunk)
        }

        // Send last chunk and get response count
        let response = try await _gaiaExtension.sendCommand(commandID: MimiGaiaCommand.protobufRequestMsgEnd.rawValue, payload: lastChunk)
        return Int(response[0])
    }

    private func receiveResponseChunks(count: Int) async throws -> Data {
        var returnData = Data()
        var remainingChunks = count

        while remainingChunks > 0 {
            let responseCommand: MimiGaiaCommand = remainingChunks > 1
                ? .protobufResponseMsgChunk
                : .protobufResponseMsgEnd

            let chunkedReturnData = try await _gaiaExtension.sendCommand(commandID: responseCommand.rawValue)
            returnData.append(chunkedReturnData)

            remainingChunks -= 1
        }

        return returnData
    }
}
