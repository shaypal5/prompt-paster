import XCTest
@testable import PromptPaster

final class PromptSearchTests: XCTestCase {
    private let prompts = [
        Prompt(
            id: "merge-check",
            title: "Merge Check",
            category: "PR",
            body: "Wait for CI and inspect failures.",
            tags: ["merge", "ci"]
        ),
        Prompt(
            id: "handoff",
            title: "New Agent Handoff",
            category: "Handoff",
            body: "Include branch, files, blockers, and validation.",
            tags: ["agent"]
        ),
        Prompt(
            id: "docs-intro",
            title: "Technical Wiki Intro",
            category: "Docs",
            body: "Write architecture and setup notes.",
            tags: ["wiki"]
        )
    ]

    func testCategoriesIncludeAllAndLoadedPromptCategories() {
        XCTAssertEqual(PromptSearch.categories(for: prompts), ["All", "Docs", "Handoff", "PR"])
    }

    func testFiltersAcrossTitleCategoryTagsAndBody() {
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "merge", category: "All").map(\.id),
            ["merge-check"]
        )
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "handoff", category: "All").map(\.id),
            ["handoff"]
        )
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "wiki", category: "All").map(\.id),
            ["docs-intro"]
        )
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "validation", category: "All").map(\.id),
            ["handoff"]
        )
    }

    func testFiltersByCategoryAndKeepsConfiguredOrder() {
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "", category: "PR").map(\.id),
            ["merge-check"]
        )
        XCTAssertEqual(
            PromptSearch.filteredPrompts(prompts, query: "", category: "All").map(\.id),
            ["merge-check", "handoff", "docs-intro"]
        )
    }
}
