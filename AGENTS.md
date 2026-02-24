# Repository Guidelines

## Project Structure & Module Organization
- `HighlightrUI/Sources/HighlightrUI`: main Swift package source.
  - `Bridge/`, `Controller/`, `Engine/`, `Types/`, `View/` split responsibilities by layer.
- `HighlightrUI/Tests`: package tests.
  - `HighlightrUICoreTests/` for model/value/runtime logic.
  - `HighlightrUITests/` for UI/controller integration behavior.
- `MiniApp/`: example iOS app (`MiniApp`) plus `MiniAppTests` and `MiniAppUITests`.
- `Docs/`: developer docs such as migration notes (`Docs/Migration.md`).
- Root manifests: `Package.swift`, `HighlightrUI.xcworkspace`.

## Test Commands
- `xcodebuild -workspace HighlightrUI.xcworkspace -scheme HighlightrUITests -destination 'platform=macOS' test`
  - Run macOS test suite via workspace scheme.
- `xcodebuild -workspace HighlightrUI.xcworkspace -scheme HighlightrUITests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' test`
  - Run iOS simulator tests.
- `xcrun simctl list devices available`
  - Check valid simulator names before running iOS commands.

## Coding Style & Naming Conventions
- Swift 6.2 / Swift language mode 6 is the baseline.
- Use Xcode default formatting: 4-space indentation, no tabs.
- Follow Swift API Design Guidelines:
  - Types: `UpperCamelCase`
  - Properties/functions: `lowerCamelCase`
- Keep platform-specific files explicit using suffixes like `+iOS.swift` and `+macOS.swift`.
- Prefer small, focused types over large view/controller files.

## Testing Guidelines
- Primary package tests use Swift Testing (`import Testing`, `@Test`, `#expect`).
- MiniApp UI tests use `XCTest` and should remain deterministic (e.g., fixed accessibility identifiers).
- Name tests by behavior, not implementation details (e.g., `automaticThemeResolvesByColorScheme`).
- Add or update tests for every bug fix and public API behavior change.

## Commit & Pull Request Guidelines
- Follow Conventional Commits as seen in history:
  - `fix(editor): preserve initial runtime undo flags`
  - `refactor(api)!: remove editor model and merge core into HighlightrUI`
- Keep commits scoped to one concern.
- PRs should include:
  - Purpose and change summary
  - Linked issue/task (if available)
  - Test commands executed and results
  - Screenshots for MiniApp UI changes
