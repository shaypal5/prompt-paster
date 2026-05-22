import XCTest
@testable import PromptPaster

final class PromptOverlayStateTests: XCTestCase {
    private let prompts = [
        Prompt(id: "first", title: "First", category: "PR", body: "First body"),
        Prompt(id: "second", title: "Second", category: "Docs", body: "Second body"),
        Prompt(id: "third", title: "Third", category: "Docs", body: "Third body")
    ]

    func testInvalidLibraryErrorTakesPrimaryEmptyState() {
        let emptyState = PromptOverlayState.emptyState(
            prompts: [],
            visiblePrompts: [],
            query: "",
            lastErrorMessage: "The data could not be read."
        )

        XCTAssertEqual(emptyState?.title, "Prompt library could not load")
        XCTAssertTrue(emptyState?.detail.contains("The data could not be read.") == true)
    }

    func testStatusMessagesIncludeCopyFailureAfterLibraryWarnings() {
        let messages = PromptOverlayState.statusMessages(
            message: "Reloaded 3 prompts.",
            validation: PromptLibraryValidation(warnings: [
                .shortcutConflict(shortcut: "1", promptIDs: ["first", "second"])
            ]),
            copyStatusMessage: "Could not copy \"First\". Clipboard write failed."
        )

        XCTAssertEqual(messages, [
            "Reloaded 3 prompts.",
            "Library loaded with 1 warning.",
            "Could not copy \"First\". Clipboard write failed."
        ])
    }

    func testEmptyLibraryAndEmptySearchHaveDifferentStates() {
        XCTAssertEqual(
            PromptOverlayState.emptyState(
                prompts: [],
                visiblePrompts: [],
                query: "",
                lastErrorMessage: nil
            ),
            PromptOverlayEmptyState(
                title: "No prompts loaded",
                detail: "Use Reload Library from the menu after adding prompts to prompts.json."
            )
        )

        XCTAssertEqual(
            PromptOverlayState.emptyState(
                prompts: prompts,
                visiblePrompts: [],
                query: "missing",
                lastErrorMessage: nil
            ),
            PromptOverlayEmptyState(
                title: "No search results",
                detail: "Try a different title, category, tag, or body term."
            )
        )
    }

    func testSelectionMovementClampsToVisiblePrompts() {
        XCTAssertEqual(
            PromptOverlayState.selectedPromptIDMoving(
                currentID: "first",
                visiblePrompts: prompts,
                offset: 1
            ),
            "second"
        )
        XCTAssertEqual(
            PromptOverlayState.selectedPromptIDMoving(
                currentID: "third",
                visiblePrompts: prompts,
                offset: 1
            ),
            "third"
        )
        XCTAssertEqual(
            PromptOverlayState.selectedPromptIDMoving(
                currentID: "first",
                visiblePrompts: prompts,
                offset: -1
            ),
            "first"
        )
    }

    func testKeepingSelectionChoosesFirstVisibleWhenCurrentIsMissing() {
        XCTAssertEqual(
            PromptOverlayState.selectedPromptIDKeepingVisible(
                currentID: "missing",
                visiblePrompts: prompts
            ),
            "first"
        )
        XCTAssertNil(
            PromptOverlayState.selectedPromptIDKeepingVisible(
                currentID: "first",
                visiblePrompts: []
            )
        )
    }

    func testPreviewTextTruncatesToConfiguredCharacterLimit() {
        let body = "1234567890abcdef"

        XCTAssertEqual(PromptOverlayState.previewText(for: body, characterLimit: 10), "1234567...")
        XCTAssertEqual(PromptOverlayState.previewText(for: body, characterLimit: 16), body)
    }

    func testPreviewLineLimitScalesWithCharacterLimit() {
        XCTAssertEqual(PromptOverlayState.previewLineLimit(for: 40), 2)
        XCTAssertEqual(PromptOverlayState.previewLineLimit(for: 120), 3)
        XCTAssertEqual(PromptOverlayState.previewLineLimit(for: 260), 5)
        XCTAssertEqual(PromptOverlayState.previewLineLimit(for: 600), 7)
    }

    func testPromptCardColumnCountAdaptsToAvailableWidth() {
        XCTAssertEqual(PromptOverlayState.promptCardColumnCount(for: 620), 1)
        XCTAssertEqual(PromptOverlayState.promptCardColumnCount(for: 860), 2)
        XCTAssertEqual(PromptOverlayState.promptCardColumnCount(for: 1_180), 3)
        XCTAssertEqual(PromptOverlayState.promptCardColumnCount(for: 1_560), 4)
        XCTAssertEqual(PromptOverlayState.promptCardColumnCount(for: 1_900), 5)
    }

    func testPromptCardSpanKeepsSmallLayoutsSingleColumn() {
        let longPrompt = Prompt(
            id: "long",
            title: "A long prompt that needs more room in a dense scanning layout",
            category: "Review",
            body: String(repeating: "Body ", count: 90),
            tags: ["swift", "review", "macos", "overlay"]
        )

        XCTAssertEqual(
            PromptOverlayState.promptCardColumnSpan(
                for: longPrompt,
                availableColumns: 2,
                previewCharacterLimit: 260
            ),
            1
        )
        XCTAssertEqual(
            PromptOverlayState.promptCardColumnSpan(
                for: longPrompt,
                availableColumns: 3,
                previewCharacterLimit: 260
            ),
            2
        )
    }

    func testPromptCardMinimumHeightScalesWithContentDensity() {
        let compactPrompt = Prompt(id: "compact", title: "Compact", category: nil, body: "Short")
        let densePrompt = Prompt(
            id: "dense",
            title: "Longer prompt title that should receive more vertical room",
            category: "Planning",
            body: String(repeating: "Preview ", count: 30),
            tags: ["scope", "handoff"]
        )

        XCTAssertEqual(
            PromptOverlayState.promptCardMinimumHeight(
                for: compactPrompt,
                previewCharacterLimit: 80
            ),
            126
        )
        XCTAssertEqual(
            PromptOverlayState.promptCardMinimumHeight(
                for: densePrompt,
                previewCharacterLimit: 260
            ),
            188
        )
    }
}
