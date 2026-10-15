import NightCastCore
import Observation
import SwiftUI

@Observable
final class SearchModel {
    enum State: Equatable {
        case idle
        case loading
        case results([DirectoryResult])
        case empty(String)
        case failed(String)
    }

    private(set) var state: State = .idle
    var query = "" {
        didSet { if query != oldValue { schedule() } }
    }

    @ObservationIgnored private let directory: DirectoryService
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var cache: [String: [DirectoryResult]] = [:]
    @ObservationIgnored private let debounce: Duration

    init(directory: DirectoryService, debounce: Duration = .milliseconds(350)) {
        self.directory = directory
        self.debounce = debounce
    }

    func retry() {
        run(immediately: true)
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    private func schedule() {
        run(immediately: false)
    }

    private func run(immediately: Bool) {
        task?.cancel()
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            state = .idle
            return
        }
        let key = term.lowercased()
        if let cached = cache[key] {
            state = cached.isEmpty ? .empty(term) : .results(cached)
            return
        }
        task = Task { [weak self, directory, debounce] in
            if !immediately {
                try? await Task.sleep(for: debounce)
            }
            guard !Task.isCancelled else { return }
            self?.state = .loading
            do {
                let results = try await directory.search(term)
                guard !Task.isCancelled else { return }
                self?.cache[key] = results
                self?.state = results.isEmpty ? .empty(term) : .results(results)
            } catch is CancellationError {
                return
            } catch let error as URLError where error.code == .cancelled {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(Self.message(for: error))
            }
        }
    }

    static func message(for error: Error) -> String {
        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "You’re offline. Check your connection and try again."
            case .timedOut:
                return "The podcast directory took too long to answer."
            default:
                break
            }
        }
        if let error = error as? DirectoryError {
            switch error {
            case .rateLimited: return "Too many searches at once. Wait a moment, then try again."
            case .http, .badResponse: return "The podcast directory isn’t responding right now."
            }
        }
        return "Search didn’t work. Try again."
    }
}

struct SearchView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var model: SearchModel
    @FocusState private var focused: Bool

    init(directory: DirectoryService, initialQuery: String? = nil) {
        let model = SearchModel(directory: directory)
        if let initialQuery { model.query = initialQuery }
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(spacing: Space.m) {
                IconKey(systemName: "chevron.left", label: "Back") {
                    model.cancel()
                    dismiss()
                }
                .accessibilityIdentifier("closeSearch")
                SearchField(text: $model.query, focused: $focused) { model.retry() }
            }
            .padding(.horizontal, Space.xl)
            .padding(.top, Space.s)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(theme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { focused = true }
        .onDisappear { model.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle:
            StateMessage(title: "Find a show", message: "Search by show name, host, or topic.", systemImage: "magnifyingglass")
        case .loading:
            VStack(spacing: Space.m) {
                ProgressView().controlSize(.large).tint(theme.text)
                Text("Searching…").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            .padding(.top, Space.huge)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("searchLoading")
        case .empty(let term):
            StateMessage(title: "No shows found", message: "Nothing matched “\(term)”. Try another spelling or a shorter name.", systemImage: "questionmark")
        case .failed(let message):
            StateMessage(title: "Couldn’t search", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                model.retry()
            }
        case .results(let results):
            ScrollView {
                LazyVStack(spacing: Space.xs) {
                    ForEach(results) { result in
                        NavigationLink(value: Route.show(result.show)) {
                            SearchRow(result: result, subscribed: app.isSubscribed(result.show))
                        }
                        .buttonStyle(RowStyle())
                    }
                }
                .padding(.horizontal, Space.m)
                .padding(.bottom, Space.xxxl)
            }
            .scrollDismissesKeyboard(.immediately)
            .accessibilityIdentifier("searchResults")
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    var onSubmit: () -> Void = {}
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(theme.textMuted)
                .accessibilityHidden(true)
            TextField("", text: $text, prompt: Text("Shows, hosts, topics").foregroundStyle(theme.textMuted))
                .font(Typo.headline)
                .foregroundStyle(theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { onSubmit() }
                .focused(focused)
                .accessibilityLabel("Search podcasts")
                .accessibilityIdentifier("searchField")
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(theme.textMuted)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, Space.l)
        .frame(minHeight: 52)
        // The field sits beside a close key; cap its growth so the clear button never overlaps the text.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .background(Capsule().fill(theme.surface))
        .overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
    }
}

private struct SearchRow: View {
    let result: DirectoryResult
    let subscribed: Bool
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s))
            : AnyLayout(HStackLayout(spacing: Space.m))
        layout {
            ArtworkView(url: result.artworkURL, cornerRadius: 10, title: result.title)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(Typo.headline)
                    .foregroundStyle(theme.text)
                    .lineLimit(typeSize.isAccessibilitySize ? 4 : 2)
                if let author = result.author {
                    Text(author)
                        .font(Typo.caption)
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Space.s)
            if subscribed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.text)
                    .accessibilityLabel("Subscribed")
            }
            if !typeSize.isAccessibilitySize {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.textMuted)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Rows highlight with the surface color while pressed.
struct RowStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isPressed ? theme.surface : .clear)
            )
    }
}

/// Shared empty / error / idle message with an optional single action.
struct StateMessage: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(theme.textMuted)
                .accessibilityHidden(true)
            Text(title)
                .font(Typo.playerTitle)
                .foregroundStyle(theme.text)
            Text(message)
                .font(Typo.body)
                .foregroundStyle(theme.textMuted)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(Typo.headline).padding(.vertical, Space.m).padding(.horizontal, Space.xl)
                }
                .buttonStyle(.capsuleKey(.primary))
                .fixedSize()
                .padding(.top, Space.s)
                .accessibilityIdentifier("retryKey")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Space.xxl)
        .padding(.top, Space.xxxl)
    }
}
