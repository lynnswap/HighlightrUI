import HighlightrUICore
import Testing
@testable import HighlightrUI

@MainActor
private func waitUntil(
    timeoutNanoseconds: UInt64 = 3_000_000_000,
    condition: @escaping @MainActor () -> Bool
) async {
    let clock = ContinuousClock()
    let start = clock.now

    while !condition() {
        if start.duration(to: clock.now) >= .nanoseconds(Int64(timeoutNanoseconds)) {
            break
        }
        await AsyncDrain.firstTurn()
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
struct EditorCoordinatorAppearanceTests {
    @Test
    func themeApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .automatic(light: "paraiso-light", dark: "paraiso-dark")
        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .named("github")
        await waitUntil {
            engine.setThemeNameCalls == ["paraiso-light", "github"]
        }
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])

        model.theme = .named("github")
        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])
    }

    @Test
    func applyAppearanceForcesAutomaticThemeReapply() async {
        let model = HighlightrEditorModel(
            text: "",
            language: "swift",
            theme: .automatic(light: "paraiso-light", dark: "paraiso-dark")
        )

        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .dark)
        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .light)
        await AsyncDrain.firstTurn()

        #expect(engine.setThemeNameCalls == ["paraiso-light", "paraiso-dark", "paraiso-light"])
    }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
struct EditorCoordinatorAppearanceTests {
    @Test
    func themeApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorModel(text: "", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .automatic(light: "paraiso-light", dark: "paraiso-dark")
        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .named("github")
        await waitUntil {
            engine.setThemeNameCalls == ["paraiso-light", "github"]
        }
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])

        model.theme = .named("github")
        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])
    }

    @Test
    func applyAppearanceForcesAutomaticThemeReapply() async {
        let model = HighlightrEditorModel(
            text: "",
            language: "swift",
            theme: .automatic(light: "paraiso-light", dark: "paraiso-dark")
        )

        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            model: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )
        defer { coordinator.invalidate() }

        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .dark)
        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .light)
        await AsyncDrain.firstTurn()

        #expect(engine.setThemeNameCalls == ["paraiso-light", "paraiso-dark", "paraiso-light"])
    }
}
#endif
