# Flyweight
iOS client for GNU social

## Status
This is very much a work in progress. The data and network layers are coming along.
The UI is barely good enough for testing, showing notices from a public timeline.
I will need to finish basic features to put it on the App Store for general usage.

## Licence
Flyweight is distributed under the Apache 2.0 license. A permissive licence is
used specifically so that derivative works can be submitted to the App Store.

Some external libraries are included in the repository that are covered by their
own copyright and licensing. Refer to file headers.

## Goals for initial release
* Ability to send and receive notices including image attachments
* Ability to repeat and favourite notices
* Ability to reply to notices and view the conversation chain as known by your server
* View home, notifications, public, TWKN and own timelines (tags, groups, other users to come later)
* Cache aggressively and use embedded database to quickly recall notices and image assets for display
* Carefully managed network operations with rock-solid error handling
* Clean touch interface that is functional on all iPhone and iPad sizes
* UI for single account only, but backend support for multiple
* Lean on server to linkify groups, tags, mentions initially

## Build instructions
* Install [CocoaPods](https://cocoapods.org)
* Open a terminal in the project directory and run `pod install`
* Open `Flyweight.xcworkspace`
* Edit `AppDelegate.swift` to set account details for testing. (There is no login screen yet.)
* Build and run
