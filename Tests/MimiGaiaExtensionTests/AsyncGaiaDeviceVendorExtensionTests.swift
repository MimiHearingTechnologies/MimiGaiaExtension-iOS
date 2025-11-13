import Testing
import Foundation
@testable import MimiGaiaExtension
import GaiaCore
import GaiaBase
import Packets
import PluginBase

// MARK: - Test Suite

@Suite("AsyncGaiaV3DeviceVendorExtension Tests")
struct AsyncGaiaDeviceVendorExtensionTests {
    
    // MARK: - Helper Methods
    
    func createExtension(vendorID: UInt16 = 0x1234, featureID: UInt8 = 0x20) -> (AsyncGaiaV3DeviceVendorExtension, MockGaiaDevice, MockGaiaConnection) {
        let device = MockGaiaDevice()
        let connection = MockGaiaConnection()
        let notificationCenter = NotificationCenter.default
        
        let ext = AsyncGaiaV3DeviceVendorExtension(
            vendorID: vendorID,
            featureID: featureID,
            name: "TestExtension",
            device: device,
            connection: connection,
            notificationCenter: notificationCenter
        )
        
        return (ext, device, connection)
    }
    
    func extractCommandID(from packetData: Data) -> UInt16? {
        // Packet structure following GaiaV3GATTPacket
        // Byte 3 contains only the lower 7 bits of commandID (bit 7 is the reason low bit)
        guard packetData.count >= 4 else { return nil }
        let commandIDByte = packetData[3]
        let commandID = UInt16(commandIDByte & 0x7F)  // Only lower 7 bits
        return commandID
    }
    
    func createResponsePacket(vendorID: UInt16, featureID: UInt8, commandID: UInt16, payload: Data = Data()) -> Data {
        // Create response packet following GaiaV3GATTPacket structure
        // Reason: .response = 0b10
        // High bit (1) goes into bit 0 of featureID byte
        // Low bit (0) goes into bit 7 of commandID byte
        var data = Data()
        data.append(contentsOf: vendorID.bigEndianBytes)
        
        // Feature byte: (featureID << 1) | (reason_high_bit & 0x01)
        let featureByte = (featureID << 1) | 0x01  // reason high bit is 1 for response
        data.append(featureByte)
        
        // Command byte: (commandID & 0x7F) | ((reason_low_bit & 0x01) << 7)
        let commandByte = UInt8(commandID & 0x7F) | 0x00  // reason low bit is 0 for response
        data.append(commandByte)
        
        data.append(contentsOf: payload)
        return data
    }
    
    func createErrorPacket(vendorID: UInt16, featureID: UInt8, commandID: UInt16, errorCode: UInt8, payload: Data = Data()) -> Data {
        // Create error packet following GaiaV3GATTPacket structure
        // Reason: .error = 0b11
        // High bit (1) goes into bit 0 of featureID byte
        // Low bit (1) goes into bit 7 of commandID byte
        var data = Data()
        data.append(contentsOf: vendorID.bigEndianBytes)
        
        // Feature byte: (featureID << 1) | (reason_high_bit & 0x01)
        let featureByte = (featureID << 1) | 0x01  // reason high bit is 1 for error
        data.append(featureByte)
        
        // Command byte: (commandID & 0x7F) | ((reason_low_bit & 0x01) << 7)
        let commandByte = UInt8(commandID & 0x7F) | 0x80  // reason low bit is 1 for error
        data.append(commandByte)
        
        // Error packet has errorCode first in payload
        data.append(errorCode)
        data.append(contentsOf: payload)
        return data
    }
    
    func createNotificationPacket(vendorID: UInt16, featureID: UInt8, notificationID: UInt8, payload: Data = Data()) -> Data {
        // Create notification packet following GaiaV3GATTPacket structure
        // Reason: .notification = 0b01
        // High bit (0) goes into bit 0 of featureID byte
        // Low bit (1) goes into bit 7 of commandID byte
        var data = Data()
        data.append(contentsOf: vendorID.bigEndianBytes)
        
        // Feature byte: (featureID << 1) | (reason_high_bit & 0x01)
        let featureByte = (featureID << 1) | 0x00  // reason high bit is 0 for notification
        data.append(featureByte)
        
        // Command byte: (notificationID & 0x7F) | ((reason_low_bit & 0x01) << 7)
        let commandByte = UInt8(notificationID & 0x7F) | 0x80  // reason low bit is 1 for notification
        data.append(commandByte)
        
        data.append(contentsOf: payload)
        return data
    }
    
    // MARK: - Command Response Tests
    
    @Test("Send command returns response data")
    func testSendCommandSuccess() async throws {
        let (ext, _, connection) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let commandID: UInt16 = 0x0001
        let expectedResponse = Data([0x42, 0x43, 0x44])
        
        // Setup mock to respond
        connection.responseHandler = { (channel: GaiaDeviceConnectionChannel, payload: Data, ack: Bool) in
            // Parse the sent command
            if let extractedCommandID = self.extractCommandID(from: payload) {
                // Simulate response
                let responseData = self.createResponsePacket(
                    vendorID: 0x1234,
                    featureID: 0x20,
                    commandID: extractedCommandID,
                    payload: expectedResponse
                )
                
                Task {
                    _ = await ext.dataReceived(responseData)
                }
            }
        }
        
        // Send command
        let response = try await ext.sendCommand(commandID: commandID, payload: Data([0x01, 0x02]))
        
        // Verify response
        #expect(response == expectedResponse)
        #expect(connection.sentData.count == 1)
        // Channel type is .command from GaiaDeviceConnectionChannel enum
        #expect(connection.sentData[0].acknowledgementExpected == true)
        
        await ext.stop()
    }
    
    @Test("Send command with empty payload")
    func testSendCommandEmptyPayload() async throws {
        let (ext, _, connection) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let commandID: UInt16 = 0x0002
        let expectedResponse = Data([0x01])
        
        connection.responseHandler = { (channel: GaiaDeviceConnectionChannel, payload: Data, ack: Bool) in
            if let _ = self.extractCommandID(from: payload) {
                let responseData = self.createResponsePacket(
                    vendorID: 0x1234,
                    featureID: 0x20,
                    commandID: commandID,
                    payload: expectedResponse
                )
                
                Task {
                    _ = await ext.dataReceived(responseData)
                }
            }
        }
        
        let response = try await ext.sendCommand(commandID: commandID)
        
        #expect(response == expectedResponse)
        
        await ext.stop()
    }
    
    @Test("Send command throws error on error response")
    func testSendCommandErrorResponse() async throws {
        let (ext, _, connection) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let commandID: UInt16 = 0x0003
        let errorCode: UInt8 = 0x05
        
        connection.responseHandler = { (channel: GaiaDeviceConnectionChannel, payload: Data, ack: Bool) in
            if let _ = self.extractCommandID(from: payload) {
                let errorData = self.createErrorPacket(
                    vendorID: 0x1234,
                    featureID: 0x20,
                    commandID: commandID,
                    errorCode: errorCode
                )
                
                Task {
                    _ = await ext.dataReceived(errorData)
                }
            }
        }
        
        // Should throw GaiaCommandError
        do {
            _ = try await ext.sendCommand(commandID: commandID)
            Issue.record("Expected error to be thrown")
        } catch let error as GaiaCommandError {
            #expect(error.command == commandID)
            #expect(error.errorCode == errorCode)
        } catch {
            Issue.record("Wrong error type thrown: \(error)")
        }
        
        await ext.stop()
    }
    
    @Test("Multiple commands can be sent sequentially")
    func testMultipleCommands() async throws {
        let (ext, _, connection) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let commandCounter = CommandCounter()
        
        connection.responseHandler = { (channel: GaiaDeviceConnectionChannel, payload: Data, ack: Bool) in
            if let extractedCommandID = self.extractCommandID(from: payload) {
                Task {
                    let count = await commandCounter.increment()
                    let responseData = self.createResponsePacket(
                        vendorID: 0x1234,
                        featureID: 0x20,
                        commandID: extractedCommandID,
                        payload: Data([UInt8(count)])
                    )
                    
                    _ = await ext.dataReceived(responseData)
                }
            }
        }
        
        // Send multiple commands
        let response1 = try await ext.sendCommand(commandID: 0x0001)
        let response2 = try await ext.sendCommand(commandID: 0x0002)
        let response3 = try await ext.sendCommand(commandID: 0x0003)
        
        #expect(response1 == Data([0x01]))
        #expect(response2 == Data([0x02]))
        #expect(response3 == Data([0x03]))
        #expect(connection.sentData.count == 3)
        
        await ext.stop()
    }
    
    @Test("Sending same command twice cancels first continuation")
    func testDuplicateCommandCancellation() async throws {
        let (ext, _, connection) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let commandID: UInt16 = 0x0001
        
        let delayController = ResponseDelayController()
        
        connection.responseHandler = { (channel: GaiaDeviceConnectionChannel, payload: Data, ack: Bool) in
            Task {
                if await delayController.getShouldRespond() {
                    // Only respond to second command
                    if let _ = self.extractCommandID(from: payload) {
                        let responseData = self.createResponsePacket(
                            vendorID: 0x1234,
                            featureID: 0x20,
                            commandID: commandID,
                            payload: Data([0x42])
                        )
                        
                        _ = await ext.dataReceived(responseData)
                    }
                }
            }
        }
        
        // Send first command (won't get response)
        let task1 = Task {
            try await ext.sendCommand(commandID: commandID)
        }
        
        // Small delay to ensure first command is registered
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await delayController.setShouldRespond(true)
        
        // Send second command (this should cancel first)
        let response2 = try await ext.sendCommand(commandID: commandID)
        
        // First command should be cancelled
        let result1 = await task1.result
        switch result1 {
        case .failure(let error):
            #expect(error is CancellationError)
        case .success:
            Issue.record("First command should have been cancelled")
        }
        
        // Second command should succeed
        #expect(response2 == Data([0x42]))
        
        await ext.stop()
    }
    
    // MARK: - Notification Tests
    
    @Test("Notifications are received through async stream")
    func testNotificationStream() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        let notificationID: UInt8 = 0x10
        let notificationData = Data([0x11, 0x22, 0x33])
        
        // Start listening for notifications
        let notificationTask = Task {
            var receivedNotifications: [(UInt8, Data)] = []
            for await notification in await ext.notifications {
                receivedNotifications.append(notification)
                if receivedNotifications.count >= 1 {
                    break
                }
            }
            return receivedNotifications
        }
        
        // Send notification
        let notificationPacket = createNotificationPacket(
            vendorID: 0x1234,
            featureID: 0x20,
            notificationID: notificationID,
            payload: notificationData
        )
        
        _ = await ext.dataReceived(notificationPacket)
        
        // Wait for notification
        let notifications = await notificationTask.value
        
        #expect(notifications.count == 1)
        #expect(notifications[0].0 == notificationID)
        #expect(notifications[0].1 == notificationData)
        
        await ext.stop()
    }
    
    @Test("Multiple notifications are received in order")
    func testMultipleNotifications() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        // Start listening for notifications
        let notificationTask = Task {
            var receivedNotifications: [(UInt8, Data)] = []
            for await notification in await ext.notifications {
                receivedNotifications.append(notification)
                if receivedNotifications.count >= 3 {
                    break
                }
            }
            return receivedNotifications
        }
        
        // Send multiple notifications
        for i: UInt8 in 1...3 {
            let packet = createNotificationPacket(
                vendorID: 0x1234,
                featureID: 0x20,
                notificationID: i,
                payload: Data([i * 10])
            )
            _ = await ext.dataReceived(packet)
        }
        
        let notifications = await notificationTask.value
        
        #expect(notifications.count == 3)
        #expect(notifications[0].0 == 1)
        #expect(notifications[1].0 == 2)
        #expect(notifications[2].0 == 3)
        
        await ext.stop()
    }
    
    // MARK: - Error Stream Tests
    
    @Test("Errors are received through async stream")
    func testErrorStream() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        // Start listening for errors
        let errorTask = Task {
            var receivedErrors: [GaiaError] = []
            for await error in await ext.errors {
                receivedErrors.append(error)
                if receivedErrors.count >= 1 {
                    break
                }
            }
            return receivedErrors
        }
        
        // Simulate error
        let testError = GaiaError.writeToDeviceTimedOut
        await ext.didError(testError)
        
        let errors = await errorTask.value
        
        #expect(errors.count == 1)
        
        await ext.stop()
    }
    
    // MARK: - Data Reception Tests
    
    @Test("Data from different vendor ID is ignored")
    func testWrongVendorIDIgnored() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        // Create packet with wrong vendor ID
        let wrongPacket = createResponsePacket(
            vendorID: 0x9999,
            featureID: 0x20,
            commandID: 0x0001,
            payload: Data([0x42])
        )
        
        let result = await ext.dataReceived(wrongPacket)
        
        // Should return true (handled, but ignored)
        #expect(result == true)
        
        await ext.stop()
    }
    
    @Test("Invalid packet data is handled gracefully")
    func testInvalidPacketData() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        // Send invalid data
        let invalidData = Data([0x00, 0x01])
        let result = await ext.dataReceived(invalidData)
        
        // Should return true (handled)
        #expect(result == true)
        
        await ext.stop()
    }
    
    // MARK: - Lifecycle Tests
    
    @Test("Stop cancels all pending commands")
    func testStopCancelsPendingCommands() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)

        await ext.start()
        
        // Don't set up response handler, so command will hang
        
        // Send command without response
        let commandTask = Task {
            try await ext.sendCommand(commandID: 0x0001)
        }
        
        // Small delay to ensure command is registered
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Stop extension
        await ext.stop()
        
        // Command should be cancelled
        let result = await commandTask.result
        switch result {
        case .failure(let error):
            #expect(error is CancellationError)
        case .success:
            Issue.record("Command should have been cancelled on stop")
        }
    }
    
    @Test("Stop finishes notification stream")
    func testStopFinishesNotificationStream() async throws {
        let (ext, _, _) = createExtension(vendorID: 0x1234, featureID: 0x20)
        
        await ext.start()
        
        // Start listening for notifications
        let notificationTask = Task {
            var count = 0
            for await _ in await ext.notifications {
                count += 1
            }
            return count
        }
        
        // Stop extension
        await ext.stop()
        
        // Stream should complete
        let count = await notificationTask.value
        #expect(count == 0) // No notifications were sent
    }
}

private actor ResponseDelayController {
    var shouldRespond = false

    func setShouldRespond(_ value: Bool) {
        shouldRespond = value
    }

    func getShouldRespond() -> Bool {
        return shouldRespond
    }
}

private actor CommandCounter {
    var count = 0
    
    func increment() -> Int {
        count += 1
        return count
    }
}
