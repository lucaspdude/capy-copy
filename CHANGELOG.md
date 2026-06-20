# Changelog

## [0.2.0](https://github.com/lucaspdude/capy-copy/compare/v0.1.3...v0.2.0) (2026-06-20)


### Features

* **ui:** batch UI and privacy improvements ([f16b393](https://github.com/lucaspdude/capy-copy/commit/f16b3938aa9555b9d1f8d83b6686ccd0451798c2))
* **ui:** implement six UI/privacy improvements ([f704386](https://github.com/lucaspdude/capy-copy/commit/f704386ecfbd82d7822a6b5c37eedd74a219f367))
* **ui:** in-popover permission gate with banner ([4c4be8a](https://github.com/lucaspdude/capy-copy/commit/4c4be8abfd10e02fb9059a7d0a25544f87627a15))


### Bug Fixes

* **ui:** apply current theme to existing popover on each show ([7931e75](https://github.com/lucaspdude/capy-copy/commit/7931e759e494df991c1dc56a5f8e5b00df96b7c1))
* **ui:** device scope selector is wider than its content ([9f06616](https://github.com/lucaspdude/capy-copy/commit/9f0661644c4030fcb0a2cf599112bc35a2eead55)), closes [#9](https://github.com/lucaspdude/capy-copy/issues/9)
* **ui:** hide vertical scrollbar in Quick Picker while keeping scroll ([02d8905](https://github.com/lucaspdude/capy-copy/commit/02d8905b83d9920e512ab3386ba74da6dbf30222)), closes [#10](https://github.com/lucaspdude/capy-copy/issues/10)
* **ui:** reduce sidebar icon and label sizes ([f942061](https://github.com/lucaspdude/capy-copy/commit/f94206166e80ed6478ca06572bf50e4fa42424d7))
* **ui:** remove background/border from clip card action buttons ([b7068d8](https://github.com/lucaspdude/capy-copy/commit/b7068d86a4f06d4f78e0df9167a632b5a0d2b73d))
* **ui:** sidebar icon-only tabs, action spacing, terminal popover radius ([3001c38](https://github.com/lucaspdude/capy-copy/commit/3001c384557de46fe9113732078a8e9e2293fd22))
* **ui:** use ScrollView showsIndicators initializer to hide scrollbar ([57adcd8](https://github.com/lucaspdude/capy-copy/commit/57adcd8091e6bf8edc599b4d23769d39affb7a0b))

## [0.1.3](https://github.com/lucaspdude/capy-copy/compare/v0.1.2...v0.1.3) (2026-06-17)


### Bug Fixes

* load bundled resources from app bundle instead of SwiftPM resource bundle ([922e132](https://github.com/lucaspdude/capy-copy/commit/922e1320c509fcbef48fcdbd25b1092cc38a95b7))
* load bundled resources from app bundle instead of SwiftPM resource bundle ([24a2b9d](https://github.com/lucaspdude/capy-copy/commit/24a2b9dbd66f538dbbc99bf1a4b82bf3c1cccba1))

## [0.1.2](https://github.com/lucaspdude/capy-copy/compare/v0.1.1...v0.1.2) (2026-06-17)


### Bug Fixes

* use PAT in release-please to trigger release workflow ([b8b29ba](https://github.com/lucaspdude/capy-copy/commit/b8b29baa02735ae675ec439c5d620f1f1ec15734))
* use PAT in release-please to trigger release workflow ([046c045](https://github.com/lucaspdude/capy-copy/commit/046c045594fe5a902840acae3505c26c29c20add))

## [0.1.1](https://github.com/lucaspdude/capy-copy/compare/v0.1.0...v0.1.1) (2026-06-17)


### Bug Fixes

* trigger release workflow on published releases ([1fe655d](https://github.com/lucaspdude/capy-copy/commit/1fe655d53257ef9069f77e8451f3e89e73018d84))
* trigger release workflow on published releases and allow manual dispatch ([0f813c0](https://github.com/lucaspdude/capy-copy/commit/0f813c0858afb1df8538a3ba44ddace317f00556))

## [0.1.0](https://github.com/lucaspdude/capy-copy/compare/v0.0.7...v0.1.0) (2026-06-17)


### Features

* add app lifecycle and dependency assembly ([00321e6](https://github.com/lucaspdude/capy-copy/commit/00321e6e10228b2be0c73e466e246734ea2bdfa9))
* add localizations, app icons and privacy manifest ([5de63a3](https://github.com/lucaspdude/capy-copy/commit/5de63a3479d9a0ad48f2145e43d13a4ee4e7d5f6))
* add settings store and maps provider preferences ([1596c27](https://github.com/lucaspdude/capy-copy/commit/1596c27351df740b42ad84182c2f071525ff58ff))
* add system helpers for calendar, maps, paste and permissions ([7a61df2](https://github.com/lucaspdude/capy-copy/commit/7a61df2ca92f2ebe2328244264d6423ef9b86916))
* implement clipboard monitoring, filtering and entropy heuristics ([397f071](https://github.com/lucaspdude/capy-copy/commit/397f07187b9ae089e92007b8c9a01608e8365e2f))
* implement CloudKit metadata sync coordinator ([be545f1](https://github.com/lucaspdude/capy-copy/commit/be545f1d0fb1a88c49a8ba732d34dffa14f7cb94))
* implement content analysis and classification ([0aeaae6](https://github.com/lucaspdude/capy-copy/commit/0aeaae672d1558585385eeaeb2d5361dea48968a))
* implement encrypted history persistence and device identity ([3172f33](https://github.com/lucaspdude/capy-copy/commit/3172f33ba9aa9f562d76e079365bd667c6353745))
* implement global hotkey and menu bar controller ([07e120d](https://github.com/lucaspdude/capy-copy/commit/07e120d2112b329461c591d5a47219bf35febe7e))
* implement SwiftUI picker, settings and onboarding views ([41d416e](https://github.com/lucaspdude/capy-copy/commit/41d416e85f67804deeac9eee6c8e02846e9229e6))


### Miscellaneous

* add app bundle packaging and notarization script ([013be60](https://github.com/lucaspdude/capy-copy/commit/013be604170a5004ba096ac3392ade3eebfef8d0))
* add GitHub Actions workflows for CI, release and release-please ([5bf7626](https://github.com/lucaspdude/capy-copy/commit/5bf762645dc8aa6660fcae6745b5d6151fcf94ae))
* add macOS entitlements for dev and production builds ([07e4594](https://github.com/lucaspdude/capy-copy/commit/07e45946876dc89a6a73499763ad3c2268a13a7f))
* configure release-please manifest and version tracking ([93f5557](https://github.com/lucaspdude/capy-copy/commit/93f55570b180700d87b8cc72921da237b727caec))
* initialize Swift package structure and ignore list ([2b3863f](https://github.com/lucaspdude/capy-copy/commit/2b3863f33fd685006fd7ce2f88e245b4675a310b))


### Documentation

* add project documentation and contribution guidelines ([7ef64f5](https://github.com/lucaspdude/capy-copy/commit/7ef64f5c0a809d9be2c6e5c12d089f031187ac3d))


### Tests

* add unit and integration tests for core modules ([eaa98da](https://github.com/lucaspdude/capy-copy/commit/eaa98dad47403b02ff439eda756b035e77907acb))
