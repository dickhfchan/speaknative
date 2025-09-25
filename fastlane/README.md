fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app identifier and App Store Connect app

### ios setup_signing

```sh
[bundle exec] fastlane ios setup_signing
```

Setup code signing automatically

### ios build_ios

```sh
[bundle exec] fastlane ios build_ios
```

Build and upload iOS app

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload build to TestFlight

### ios submit_metadata

```sh
[bundle exec] fastlane ios submit_metadata
```

Upload only metadata (no binary) to App Store Connect

### ios upload_to_appstore

```sh
[bundle exec] fastlane ios upload_to_appstore
```

Upload metadata and binary to App Store Connect (not auto-submit)

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata only

### ios submit_for_review

```sh
[bundle exec] fastlane ios submit_for_review
```

Submit app for App Store review

### ios distribute

```sh
[bundle exec] fastlane ios distribute
```

Distribute app - upload metadata and submit for App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
