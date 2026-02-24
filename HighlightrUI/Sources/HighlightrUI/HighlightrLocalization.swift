import Foundation

@inline(__always)
func highlightrLocalized(
    _ key: String.LocalizationValue,
    locale: Locale = .current
) -> String {
    String(localized: key, bundle: .module, locale: locale)
}
