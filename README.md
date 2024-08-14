# Ryu

<div align="center">

<img src="https://raw.githubusercontent.com/cranci1/Ryu/main/Ryu/Assets.xcassets/AppIcon.appiconset/1024.jpg" width="240px">

[![Build and Release IPA](https://github.com/cranci1/Ryu/actions/workflows/build.yml/badge.svg)](https://github.com/cranci1/Ryu/actions/workflows/build.yml) [![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%2014.0%2B-orange?logo=apple&logoColor=white)](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%2014.0%2B-red?logo=apple&logoColor=white) [![Commit](https://custom-icon-badges.demolab.com/github/last-commit/cranci1/Ryu)](https://custom-icon-badges.demolab.com/github/last-commit/cranci1/Ryu) [![Version](https://custom-icon-badges.demolab.com/github/v/release/cranci1/Ryu)](https://custom-icon-badges.demolab.com/github/v/release/cranci1/Ryu) [![Testflight](https://img.shields.io/badge/Join-Testflight-008080)](https://testflight.apple.com/join/Sxyg9JXF) [![Discord](https://img.shields.io/discord/1260315262272536698.svg?logo=discord&color=blue)](https://discord.gg/vjSTWbpeHa)

A simple way to enjoy and watch anime on iOS devices

</div>

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Features](#features)
- [Sources](#sources)
- [Installation](#installation)
- [Compatibility](#compatibility)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Acknowledgements](#acknowledgements)
- [Contributing](#contributing)
- [Localization](#localization)
- [License](#license)

## Features

- [x] Ads Free and no logins
- [x] Streaming & Download support
- [x] Third-party anime services push updates (AniList.co)
- [x] Background playback and Picture-in-Picture (PiP) support
- [x] Favorite system
- [x] Multi-source support for streaming and downloads
- [x] Google Cast support
- [x] Backup system (import, export)
- [x] Offline mode (with ongoing improvements)
- [ ] Notifications for new episodes (coming soon)
- [ ] macOS support

## Sources

| Sources     | Language   | Search | AnimeInfo | Streaming | Download |
| ----------- | ---------- | ------ | --------- | --------- | -------- |
| AnimeWorld  | Italian    | ✅     | ✅        | ✅        | ✅       |
| GoGoAnime   | English    | ✅     | ✅        | ✅        | :x:      |
| AnimeHeaven | English    | ✅     | ✅        | ✅        | ✅       |
| AnimeFire   | Portuguese | ✅     | ✅        | ✅        | ✅       |
| Kuramanime  | Indonesian | ✅     | ✅        | ✅        | ✅       |
| Anime3rb    | Arabic     | ✅     | ✅        | ✅        | ✅       |
| JKanime     | Spanish    | ✅     | ✅        | ✅        | :x:      |

> [!Note]
> AnimeFire is region Blocked. Only Portugal and Brazil IP are allowed!

## Installation

1. **TestFlight (Recommended)**:
   Join the [TestFlight beta](https://testflight.apple.com/join/Sxyg9JXF) for automatic updates.

2. **Alternative Methods**:
   - AltStore
   - Sidestore
   - TrollStore (Note: Downloads may not work)
   - Esign
   - Any other IPA installation tool

You can find the dev ipa file on [nightly.link](https://nightly.link/cranci1/Ryu/workflows/build/main) or the stable ipa on [releases](https://github.com/cranci1/Ryu/releases)

## Compatibility

- iOS/iPadOS 14.0 or later
- M-series Macs via TestFlight

## Frequently Asked Questions

1. **What is Ryu?**
   Ryu is a free, ad-free anime streaming app for iOS and iPadOS.

2. **Is Ryu legal?**
   While using Ryu may not directly break laws, check your local regulations regarding streaming content.

3. **Will Ryu be on the App Store?**
   There are no plans for an App Store release, but Ryu is available on TestFlight.

4. **Is Ryu safe?**
   Yes, Ryu is open-source and doesn't store user data on external servers.

5. **Will Ryu ever be paid?**
   No, Ryu will always remain free without subscriptions or paid content.

6. **Why I'm joing beta for AnimeGen?**
   To be able to be on TestFlight Ryu is using the same TestFlight as an other iOS app made by cranci, AnimeGen. But don't worry you will install Ryu not AnimeGen.

## Acknowledgements

Ryu contains code from the following open-source projects:

- [NineAnimator](https://github.com/SuperMarcus/NineAnimator) - GPLv3.0 License
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - MIT License
- [KingFisher](https://github.com/onevcat/Kingfisher) - MIT License
- [Alamofire](https://github.com/Alamofire/Alamofire) - MIT License
- [GoogleCastSDK-ios-no-bluetooth](https://github.com/onevcat/Kingfisher) - Google Developer Terms

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Make your changes
3. Make sure that the app is not crashing and fully working
4. Commit your changes + Push the changes to your forked repo
5. Open a Pull Request describing what changed

## Localization

If you want to translate the app in your native language its pretty simple to do:

1. Fork the repository on the [Localization](https://github.com/cranci1/Ryu/tree/Localization) branch
2. Change the Localizations File
3. Translate the Strings in your language but make sure to not translate the sources name
4. Commit your changes + Push the changes to your forked repo
5. Open a Pull Request with title "Language Localization added"

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

```
Copyright © 2024 cranci. All rights reserved.

Ryu is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Ryu is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Ryu. If not, see <https://www.gnu.org/licenses/>.
```
