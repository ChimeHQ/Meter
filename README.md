[![Github CI](https://github.com/ChimeHQ/Meter/workflows/CI/badge.svg)](https://github.com/ChimeHQ/Meter/actions)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

# Meter

Meter is a companion library to [MetricKit](https://developer.apple.com/documentation/metrickit). It aims to provide the following capabilities:

- API for `MXCallStackTree`
- MXMetricManager-like interface for unsupported platforms
- On-device symbolication

Meter is still a work in progress.

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

As of beta 1 of iOS 14, the MetricKit API for crash reporting is very unwieldy. In particular, `MXCallStackTree` lacks any kind of interface for interacting with its structure. Meter includes some classes that make it much easier to work with.

### MXMetricManager and Diagnostics Polyfill

MetricKit's crash reporting facilities will require iOS 14, and isn't supported at all for tvOS, watchOS, or macOS. You may want to start moving towards using it as a standard interface between your app and whatever system consumes the data. Meter offers an API that's very similar to MetricKit's `MXMetricManager` to do just that.

This makes it easier to support the full capabilities when available, and gracefully degrade when it is not. It will still be up to you to translate other sources of crash data. But, it can be reall desirable to have a uniform interface to whatever backend system you are using to consume the reports. And, as you move towards an iOS 14 minimum, and as (hopefully) Apple starts supporting MetricKit on more platforms, its easier to pull out the legacy code.

### On-Device Symbolication

The stack traces provided by MetricKit, like other types of crash logs, are not symbolicated. There are a bunch of different ways to tackle this problem, but one very convenient option is just to do it as a post-processing step on the device where the crash occured. The `dlopen` family of APIs could be one approach. It has has some real limitions in the past, particularly on iOS. But, still worth a look.

Right now, this functionaity is still in the investigation phase. But, if you have thoughts, please get in touch!

### Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.