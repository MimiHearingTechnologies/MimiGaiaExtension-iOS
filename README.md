# MimiGaiaExtension-iOS

## Overview

The `MimiGaiaExtension` library provides an interface for communicating with Mimi-enabled Qualcomm devices through the Gaia protocol.

**Note:** The MimiGaiaExtension currently only supports Protobuf based Mimi Automatic Processing. Support for Mimi Basic Processing hasn't been added yet.


## Requirements

- iOS 15.0+
- Swift 5.10+
- Following Gaia Frameworks: `GaiaCore`, `Packets`, `GaiaBase`, `GaiaLogger`

### Gaia Frameworks
⚠️ The extension depends on the proprietary Qualcomm GAIA iOS Frameworks. These are not bundled here and you will need to provide your own copy.

## Usage

### 1. Create and register the Extension

First, create and register an instance of `MimiAutomaticProcessingGaiaExtension`:

```swift
VendorExtensionManager.shared.register { (device, connection, notificationCenter) -> GaiaDeviceVendorExtensionProtocol in
    let mimiExtension = MimiAutomaticProcessingGaiaExtension(device: device, connection: connection, notificationCenter: notificationCenter)
    self.mimiGaiaExtension = mimiExtension // Hold on to the extension
    return mimiExtension.gaiaExtension
}
```

### 2. Verify Device Compatibility

Check if the connected device supports Mimi functionality:

```swift
let isMimiSupported = try await mimiGaiaExtension.isMimiDevice()
if isMimiSupported {
    print("Device supports Mimi Processing")
}
```

If the headphone supports Mimi, then you can proceed to activating the Mimi Processing Session.

### 3. Activate Mimi Processing Session

Use the extension to create a `MimiAutomaticProcessingConfiguration`:

```swift
let configuration = try MimiAutomaticProcessingConfiguration {
    Processor {
        Applicator { value in
            try await self.mimiGaiaExtension.send(value)
        }
    }
}

// Use the configuration to activate Mimi processing
try await processing.activate(configuration: configuration)
```

### 4. Deactivate the Processing Session instance upon Headphone disconnection

Upon headphone disconnection, you only deactivate the Mimi Processing Session; there is no specific action required for the Mimi GAIA Extension Plugin.

```swift
// Deactivate ProcessingSession

try await processing.deactivate()
```
