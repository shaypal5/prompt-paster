import SwiftUI

struct PromptOverlayView: View {
    @ObservedObject var promptStore: PromptStore

    let message: String?
    let close: () -> Void

    @State private var query = ""
    @State private var selectedCategory = PromptSearch.allCategory
    @State private var selectedPromptID: Prompt.ID?
    @State private var acknowledgement: String?
    @FocusState private var isSearchFocused: Bool

    private var prompts: [Prompt] {
        promptStore.library?.prompts ?? []
    }

    private var categories: [String] {
        PromptSearch.categories(for: prompts)
    }

    private var visiblePrompts: [Prompt] {
        PromptSearch.filteredPrompts(prompts, query: query, category: selectedCategory)
    }

    private var selectedIndex: Int? {
        guard let selectedPromptID else {
            return nil
        }
        return visiblePrompts.firstIndex { $0.id == selectedPromptID }
    }

    private var searchStrokeStyle: AnyShapeStyle {
        isSearchFocused
            ? AnyShapeStyle(Color.accentColor.opacity(0.55))
            : AnyShapeStyle(Color(nsColor: .separatorColor).opacity(0.5))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.separator.opacity(0.6), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                header
                categoryChips
                statusArea
                resultArea
            }
            .padding(22)
        }
        .padding(1)
        .frame(minWidth: 760, minHeight: 480)
        .onAppear {
            selectedCategory = PromptSearch.allCategory
            selectFirstVisiblePrompt()
            isSearchFocused = true
        }
        .onChange(of: query) { _, _ in
            keepSelectionVisible()
        }
        .onChange(of: selectedCategory) { _, _ in
            keepSelectionVisible()
        }
        .onChange(of: prompts) { _, _ in
            keepSelectionVisible()
        }
        .onExitCommand(perform: close)
        .onMoveCommand(perform: handleMoveCommand)
        .onSubmit(selectCurrentPrompt)
        .onKeyPress(.return) {
            selectCurrentPrompt()
            return .handled
        }
        .onKeyPress(characters: .decimalDigits) { keyPress in
            handleDigitShortcut(keyPress.characters)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TextField("Search prompts", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isSearchFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.background.opacity(0.74), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(searchStrokeStyle, lineWidth: 1)
                )

            Text("\(visiblePrompts.count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 34)

            Button("Close", action: close)
                .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.callout.weight(.medium))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .foregroundStyle(selectedCategory == category ? .primary : .secondary)
                            .background(
                                chipBackgroundStyle(isSelected: selectedCategory == category),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 34)
    }

    @ViewBuilder
    private var statusArea: some View {
        let messages = statusMessages
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var statusMessages: [String] {
        var messages: [String] = []

        if let message, !message.isEmpty {
            messages.append(message)
        }

        if let lastErrorMessage = promptStore.lastErrorMessage {
            messages.append("Library reload error: \(lastErrorMessage)")
        } else if let validation = promptStore.validation, !validation.warnings.isEmpty {
            messages.append("Library loaded with \(validation.warnings.count) warning\(validation.warnings.count == 1 ? "" : "s").")
        }

        if let acknowledgement {
            messages.append(acknowledgement)
        }

        return messages
    }

    @ViewBuilder
    private var resultArea: some View {
        if prompts.isEmpty {
            OverlayEmptyState(
                title: "No prompts loaded",
                detail: "Use Reload Library from the menu after adding prompts to prompts.json."
            )
        } else if visiblePrompts.isEmpty {
            OverlayEmptyState(
                title: "No search results",
                detail: "Try a different title, category, tag, or body term."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(visiblePrompts.enumerated()), id: \.element.id) { index, prompt in
                        PromptRowView(
                            prompt: prompt,
                            shortcutBadge: index < 9 ? "\(index + 1)" : nil,
                            isSelected: prompt.id == selectedPromptID
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectPrompt(at: index)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .up:
            moveSelection(by: -1)
        case .down:
            moveSelection(by: 1)
        case .left, .right:
            break
        @unknown default:
            break
        }
    }

    private func handleDigitShortcut(_ characters: String) -> KeyPress.Result {
        guard let digit = Int(characters), (1...9).contains(digit) else {
            return .ignored
        }

        let index = digit - 1
        guard visiblePrompts.indices.contains(index) else {
            return .handled
        }

        selectPrompt(at: index)
        return .handled
    }

    private func chipBackgroundStyle(isSelected: Bool) -> AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(.selection.opacity(0.24))
            : AnyShapeStyle(.background.opacity(0.48))
    }

    private func moveSelection(by offset: Int) {
        guard !visiblePrompts.isEmpty else {
            selectedPromptID = nil
            return
        }

        let currentIndex = selectedIndex ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), visiblePrompts.count - 1)
        selectedPromptID = visiblePrompts[nextIndex].id
        acknowledgement = nil
    }

    private func keepSelectionVisible() {
        guard !visiblePrompts.isEmpty else {
            selectedPromptID = nil
            acknowledgement = nil
            return
        }

        if let selectedPromptID, visiblePrompts.contains(where: { $0.id == selectedPromptID }) {
            return
        }

        selectFirstVisiblePrompt()
    }

    private func selectFirstVisiblePrompt() {
        selectedPromptID = visiblePrompts.first?.id
        acknowledgement = nil
    }

    private func selectCurrentPrompt() {
        guard let selectedIndex else {
            return
        }
        selectPrompt(at: selectedIndex)
    }

    private func selectPrompt(at index: Int) {
        guard visiblePrompts.indices.contains(index) else {
            return
        }

        let prompt = visiblePrompts[index]
        selectedPromptID = prompt.id
        acknowledgement = "Selected \"\(prompt.title)\". Clipboard copy and close are planned for CLIPBOARD-1."
    }
}

private struct PromptRowView: View {
    let prompt: Prompt
    let shortcutBadge: String?
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(prompt.title)
                        .font(.headline)
                        .lineLimit(1)

                    if let category = prompt.category, !category.isEmpty {
                        Text(category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: Capsule())
                    }
                }

                Text(prompt.body)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !prompt.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(prompt.tags.prefix(5).enumerated()), id: \.offset) { _, tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.background.opacity(0.45), in: Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 12)

            if let shortcutBadge {
                Text(shortcutBadge)
                    .font(.headline.monospacedDigit().weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 30, height: 30)
                    .background(badgeBackgroundStyle, in: RoundedRectangle(cornerRadius: 7))
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(rowBackgroundStyle, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(rowStrokeStyle, lineWidth: 1)
        )
    }

    private var badgeBackgroundStyle: AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(Color.accentColor)
            : AnyShapeStyle(.background.opacity(0.6))
    }

    private var rowBackgroundStyle: AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(.selection.opacity(0.18))
            : AnyShapeStyle(.background.opacity(0.56))
    }

    private var rowStrokeStyle: AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(Color.accentColor.opacity(0.65))
            : AnyShapeStyle(Color(nsColor: .separatorColor).opacity(0.35))
    }
}

private struct OverlayEmptyState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(.background.opacity(0.42), in: RoundedRectangle(cornerRadius: 10))
    }
}
