import Testing
@testable import HighlightrUICore

struct EditorThemeTests {
    @Test
    func automaticThemeResolvesByColorScheme() {
        let theme = EditorTheme.automatic(light: "paraiso-light", dark: "paraiso-dark")

        #expect(theme.resolvedThemeName(for: .light) == "paraiso-light")
        #expect(theme.resolvedThemeName(for: .dark) == "paraiso-dark")
    }

    @Test
    func namedThemeAlwaysResolvesToSameName() {
        let theme = EditorTheme.named("github")

        #expect(theme.resolvedThemeName(for: .light) == "github")
        #expect(theme.resolvedThemeName(for: .dark) == "github")
    }
}
