import Testing
@testable import HighlightrUI

#if canImport(UIKit)
import UIKit

@MainActor
struct EditorCoordinatorAppearanceTests {
    @Test
    func themeApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorView(text: "", language: "swift")
        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .automatic(light: "paraiso-light", dark: "paraiso-dark")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .named("github")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])

        model.theme = .named("github")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func applyAppearanceForcesAutomaticThemeReapply() async {
        let model = HighlightrEditorView(
            text: "",
            language: "swift",
            theme: .automatic(light: "paraiso-light", dark: "paraiso-dark")
        )

        let textView = PlatformEditorTextView(frame: .zero, textContainer: nil)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .dark)
        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .light)
        await AsyncDrain.firstTurn()

        #expect(engine.setThemeNameCalls == ["paraiso-light", "paraiso-dark", "paraiso-light"])
        withExtendedLifetime(coordinator) {}
    }
}

#elseif canImport(AppKit)
import AppKit

@MainActor
struct EditorCoordinatorAppearanceTests {
    @Test
    func themeApplyDeduplicatesRepeatedValues() async {
        let model = HighlightrEditorView(text: "", language: "swift")
        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .automatic(light: "paraiso-light", dark: "paraiso-dark")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light"])

        model.theme = .named("github")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])

        model.theme = .named("github")
        coordinator.syncViewFromOwner()
        #expect(engine.setThemeNameCalls == ["paraiso-light", "github"])
        withExtendedLifetime(coordinator) {}
    }

    @Test
    func applyAppearanceForcesAutomaticThemeReapply() async {
        let model = HighlightrEditorView(
            text: "",
            language: "swift",
            theme: .automatic(light: "paraiso-light", dark: "paraiso-dark")
        )

        let textView = NSTextView(frame: .zero)
        let engine = MockSyntaxHighlightingEngine()
        let coordinator = EditorCoordinator(
            owner: model,
            textView: textView,
            engine: engine,
            initialColorScheme: .light
        )

        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .dark)
        await AsyncDrain.firstTurn()
        coordinator.applyAppearance(colorScheme: .light)
        await AsyncDrain.firstTurn()

        #expect(engine.setThemeNameCalls == ["paraiso-light", "paraiso-dark", "paraiso-light"])
        withExtendedLifetime(coordinator) {}
    }
}
#endif
