[![Github CI](https://github.com/ChimeHQ/Meter/workflows/CI/badge.svg)](https://github.com/ChimeHQ/Meter/actions)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

# Meter

Meter is a companion library to [MetricKit](https://developer.apple.com/documentation/metrickit). It aims to provide the following capabilities:

- API for `MXCallStackTree`
- Types for `MXDiagnostic` emulation and coding
- `MXMetricManager`-like interface for unsupported platforms
- On-device symbolication (still under investigation)

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/Meter.git")
]
```

### Carthage

```
github "ChimeHQ/Meter"
```

### Expanded API

The MetricKit API for crash reporting is unwieldy. In particular, `MXCallStackTree` lacks any kind of interface for interacting with its structure. Meter includes some classes that make it easier to work with. In addition to providing an API for `MXCallStackTree`, Meter includes types to emulate MetricKey diagnostics.

```swift
let data = mxTree.jsonRepresentation()
let tree = try CallStackTree.from(data: data)

for frame in tree.callStacks[0].frames {
    print("\(frame.address) \(frame.binaryName) \(frame.binaryUUID)")
}
```

### MXMetricManager and Diagnostics Polyfill

MetricKit's crash reporting facilities will require iOS 14, and isn't supported at all for tvOS, watchOS, or macOS. You may want to start moving towards using it as a standard interface between your app and whatever system consumes the data. Meter offers an API that's very similar to MetricKit's `MXMetricManager` to help do just that.

This makes it easier to support the full capabilities when available, and gracefully degrade when they aren't. It will still be up to you to translate other sources of crash data. But, it can be nice to have a uniform interface to whatever backend system you are using to consume the reports. And, as you move towards an iOS 14 minimum, and as (hopefully) Apple starts supporting MetricKit on more platforms, its easier to pull out the legacy code.

```swift
// adding a subscriber
MeterPayloadManager.shared.add(obj)

extension MyObject: MeterPayloadSubscriber {
    func didReceive(_ payloads: [DiagnosticPayloadProtocol]) {
        print("received payloads \(payloads)")
    }
}

// posting diagnostics
PayloadProvider.shared.deliver(payloads)
```

### On-Device Symbolication

The stack traces provided by MetricKit, like other types of crash logs, are not symbolicated. There are a bunch of different ways to tackle this problem, but one very convenient option is just to do it as a post-processing step on the device where the crash occured. The `dlopen` family of APIs could be one approach. It has had some real limitions in the past, particularly on iOS. But, still worth a look.

Right now, this functionality is still in the investigation phase. But, if you have thoughts, please get in touch!

### Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
