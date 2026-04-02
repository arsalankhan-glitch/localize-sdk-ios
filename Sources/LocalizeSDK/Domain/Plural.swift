import Foundation

/// Plural form selection based on count.
/// CLDR rules: https://unicode-org.github.io/cldr-staging/charts/43/supplemental/language_plural_rules.html
/// Common forms: zero, one, two, few, many, other
public func selectPluralForm(locale: String, count: Int) -> String {
    let lang = locale.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? locale
    let langLower = lang.lowercased()

    switch langLower {
    case "ar":
        return arabicPlural(count)
    case "ru", "uk", "pl":
        return slavicPlural(count)
    case "fr":
        return frenchPlural(count)
    default:
        return defaultPlural(count)
    }
}

private func defaultPlural(_ count: Int) -> String {
    count == 1 ? "one" : "other"
}

private func arabicPlural(_ count: Int) -> String {
    if count == 0 { return "zero" }
    if count == 1 { return "one" }
    if count == 2 { return "two" }
    if count >= 3 && count <= 10 { return "few" }
    if count >= 11 && count <= 99 { return "many" }
    return "other"
}

private func slavicPlural(_ count: Int) -> String {
    if count % 10 == 1 && count % 100 != 11 { return "one" }
    if count % 10 >= 2 && count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20) {
        return "few"
    }
    if count % 10 == 0 ||
        (count % 10 >= 5 && count % 10 <= 9) ||
        (count % 100 >= 11 && count % 100 <= 19) {
        return "many"
    }
    return "other"
}

private func frenchPlural(_ count: Int) -> String {
    (count == 0 || count == 1) ? "one" : "other"
}
