import Foundation

public enum EditorColorScheme: Hashable, Sendable {
    case light
    case dark
}

public enum EditorTheme: Hashable, Sendable {
    case automatic(light: String, dark: String)
    case named(String)

    public func resolvedThemeName(for colorScheme: EditorColorScheme) -> String {
        switch self {
        case let .automatic(light, dark):
            return colorScheme == .dark ? dark : light
        case let .named(name):
            return name
        }
    }
}
