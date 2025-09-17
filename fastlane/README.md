# Fastlane

This folder contains lanes to build and upload the iOS app and metadata.

## Files
- fastlane/Fastfile – lanes for build (build_ios), TestFlight (beta), metadata (submit_metadata), App Store (appstore)
- fastlane/Appfile – bundle id and optional team IDs
- fastlane/api_key.json – App Store Connect API key (not committed)

## Usage
- Build IPA: `bundle exec fastlane ios build_ios`
- Upload TestFlight: `bundle exec fastlane ios beta`
- Upload metadata only: `bundle exec fastlane ios submit_metadata`
- Upload app (no auto-submit): `bundle exec fastlane ios appstore`

## Credentials
Create an App Store Connect API key and save as fastlane/api_key.json with fields: `key_id`, `issuer_id`, and `key` (contents of .p8).
