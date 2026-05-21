import Foundation

struct PromptSearch {
    static let allCategory = "All"

    static func categories(for prompts: [Prompt]) -> [String] {
        let categories = prompts.compactMap { prompt in
            let trimmed = prompt.category?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }

        return [allCategory] + Array(Set(categories)).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    static func filteredPrompts(
        _ prompts: [Prompt],
        query: String,
        category: String
    ) -> [Prompt] {
        let normalizedQuery = normalize(query)
        let normalizedCategory = normalize(category)

        return prompts.filter { prompt in
            let matchesCategory = normalizedCategory == normalize(allCategory)
                || normalize(prompt.category ?? "") == normalizedCategory
            guard matchesCategory else {
                return false
            }

            guard !normalizedQuery.isEmpty else {
                return true
            }

            return searchableText(for: prompt).contains(normalizedQuery)
        }
    }

    private static func searchableText(for prompt: Prompt) -> String {
        normalize(
            [
                prompt.title,
                prompt.category ?? "",
                prompt.tags.joined(separator: " "),
                prompt.body
            ].joined(separator: " ")
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
