# MimiGaiaExtension-iOS

## Overview

The `MimiGaiaExtension` library provides an interface for communicating with Mimi-enabled Qualcomm devices through the Gaia protocol.

> **Note:** The MimiGaiaExtension currently only supports Protobuf based Mimi Automatic Processing. Support for Mimi Basic Processing hasn't been added yet.


## Usage

### Creating and registering the Extension

First, create and register an instance of `MimiAutomaticProcessingGaiaExtension`:

```swift
VendorExtensionManager.shared.register { (device, connection, notificationCenter) -> GaiaDeviceVendorExtensionProtocol in
    let mimiExtension = MimiAutomaticProcessingGaiaExtension(device: device, connection: connection, notificationCenter: notificationCenter)
    self.mimiGaiaExtension = mimiExtension // Hold on to the extension
    return mimiExtension.gaiaExtension
}
```

### Verifying Device Compatibility

Check if the connected device supports Mimi functionality:

```swift
let isMimiSupported = try await mimiGaiaExtension.isMimiDevice()
if isMimiSupported {
    print("Device supports Mimi Processing")
}
```

### Configuring Mimi Automatic Processing

Use the extension to create a `MimiAutomaticProcessingConfiguration`:

```swift
let configuration = try MimiAutomaticProcessingConfiguration {
    Processor {
        Applicator { value in
            try await self.mimiGaiaExtension.send(value)
        }
    }
}
```

Once configured, activate Mimi processing:

```swift
try await processing.activate(configuration: configuration)
```

## Requirements

- iOS 15.0+
- Swift 5.5+
- Gaia SDK
