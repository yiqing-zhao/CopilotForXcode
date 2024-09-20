# Development

## Prerequisites

Requires Node installed and `npm` available on your system path, e.g.

```sh
sudo ln -s `which npm` /usr/local/bin
```

## Local Language Server

To run the language server locally create a `Config.local.xcconfig` file with two config values:

```xcconfig
LANGUAGE_SERVER_PATH=~/code/copilot-client
NODE_PATH=/opt/path/to/node
```

`LANGUAGE_SERVER_PATH` should point to the path where the copilot-client repo is
checked out and `$(LANGUAGE_SERVER_PATH)/dist/language-server.js` must exist
(run `npm run build`).

`NODE_PATH` should point to where node is installed. It can be omitted if
`/usr/bin/env node` will resolves directly.

## Targets 

### Copilot for Xcode

Copilot for Xcode is the host app containing both the XPCService and the editor extension. It provides the settings UI.

### EditorExtension

As its name suggests, the Xcode source editor extension. Its sole purpose is to forward editor content to the XPCService for processing, and update the editor with the returned content. Due to the sandboxing requirements for editor extensions, it has to communicate with a trusted, non-sandboxed XPCService (CommunicationBridge and ExtensionService) to bypass the limitations. The XPCService service name must be included in the `com.apple.security.temporary-exception.mach-lookup.global-name` entitlements.

### ExtensionService

The `ExtensionService` is a program that operates in the background. All features are implemented in this target.

### CommunicationBridge

It's responsible for maintaining the communication between the Copilot for Xcode/EditorExtension and ExtensionService.

### Core and Tool

Most of the logics are implemented inside the package `Core` and `Tool`.

- The `Service` contains the implementations of the ExtensionService target.
- The `HostApp` contains the implementations of the Copilot for Xcode target.

## Building and Archiving the App

1. Update the xcconfig files, bridgeLaunchAgent.plist, and Tool/Configs/Configurations.swift.
2. Build or archive the Copilot for Xcode target.
3. If Xcode complains that the pro package doesn't exist, please remove the package from the project.

## Testing Source Editor Extension

Just run both the `ExtensionService`, `CommunicationBridge` and the `EditorExtension` Target. Read [Testing Your Source Editor Extension](https://developer.apple.com/documentation/xcodekit/testing_your_source_editor_extension) for more details.

## SwiftUI Previews

Looks like SwiftUI Previews are not very happy with Objective-C packages when running with app targets. To use previews, please switch schemes to the package product targets.

## Unit Tests

To run unit tests, just run test from the `Copilot for Xcode` target.

For new tests, they should be added to the `TestPlan.xctestplan`.

## Code Style

We use SwiftFormat to format the code.

The source code mostly follows the [Ray Wenderlich Style Guide](https://github.com/raywenderlich/swift-style-guide) very closely with the following exception:

- Use the Xcode default of 4 spaces for indentation.

## App Versioning

The app version and all targets' version in controlled by `Version.xcconfig`.