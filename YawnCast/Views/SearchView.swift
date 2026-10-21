import YawnCastCore
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

/// A home page that can search in place. Both layers stay mounted; switching
/// only animates opacity, offset and scale, so nothing re-lays out mid-animation.
/// The page drifts down, shrinks a touch and fades; the search layer fades in a
/// beat later. Reduce Motion gets a plain cross-fade.
struct SearchablePage<Content: View>: View {
    let page: HomePage
    @ViewBuilder let content: Content
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var resultsHeight: CGFloat = 0

    private var isSearching: Bool { app.searchingOn == page }

    var body: some View {
        ZStack(alignment: .top) {
            content
                // Fade quickly so the two layers barely overlap; the drift/shrink
                // below follows the (slower) smooth transaction from AppModel.
                .animation(isSearching ? .easeOut(duration: 0.18) : .easeOut(duration: 0.3).delay(0.1)) {
                    $0.opacity(isSearching ? 0 : 1)
                }
                .scaleEffect(isSearching && !reduceMotion ? 0.965 : 1, anchor: .top)
                .offset(y: isSearching && !reduceMotion ? 64 : 0)
                .allowsHitTesting(!isSearching)
                .accessibilityHidden(isSearching)

            VStack(alignment: .leading, spacing: Space.l) {
                InlineSearchBar(isActive: isSearching, placeholder: page == .library ? "Your shows or new ones" : "Shows, hosts, topics")
                    .padding(.horizontal, Space.xl)
                    .padding(.top, Space.s)
                ScrollView {
                    SearchResultsView(includeLibrary: page == .library)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Space.xl)
                        .padding(.bottom, Space.xxxl)
                        // Fill the viewport so a tap on blank space anywhere below
                        // the results cancels search. Rows and buttons still win.
                        .frame(minHeight: resultsHeight, alignment: .top)
                        .contentShape(Rectangle())
                        .onTapGesture { app.endSearch() }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { resultsHeight = $0 }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .dockAware()
            }
            .opacity(isSearching ? 1 : 0)
            .offset(y: isSearching || reduceMotion ? 0 : -12)
            .allowsHitTesting(isSearching)
            .accessibilityHidden(!isSearching)
            // Arrive once the page has mostly faded; leave quickly.
            .animation(isSearching ? .smooth(duration: 0.34).delay(0.16) : .easeIn(duration: 0.14), value: isSearching)
        }
    }
}

/// Search field + Cancel at the top of a searching page.
struct InlineSearchBar: View {
    let isActive: Bool
    var placeholder = "Shows, hosts, topics"
    @Environment(AppModel.self) private var app
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var search = app.search
        HStack(spacing: Space.m) {
            SearchField(text: $search.query, focused: $focused, placeholder: placeholder) { search.retry() }
            Button("Cancel") { app.endSearch() }
                .font(Typo.headline)
                .foregroundStyle(theme.text)
                .frame(minHeight: 44)
                .accessibilityIdentifier("closeSearch")
        }
        .onChange(of: isActive) { _, active in
            if active { focusIfRequested() } else { focused = false }
        }
        .onAppear { if isActive { focusIfRequested() } }
    }

    /// Raise the keyboard just after the fade starts (not when returning from a show).
    private func focusIfRequested() {
        guard app.focusSearchOnAppear else { return }
        app.focusSearchOnAppear = false
        Task {
            try? await Task.sleep(for: .milliseconds(160))
            focused = true
        }
    }
}

/// Search states and results, laid out inside the page's own scroll view.
/// On Library: matching saved shows first ("In your Library"), then new shows from the directory.
struct SearchResultsView: View {
    var includeLibrary = false
    @Environment(AppModel.self) private var app
    @Environment(\.theme) private var theme

    private var term: String { app.search.query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Saved shows whose title or host contains the query (instant, no network).
    private var libraryMatches: [Show] {
        guard includeLibrary, !term.isEmpty else { return [] }
        return app.library.subscriptions.filter {
            $0.title.localizedCaseInsensitiveContains(term) || ($0.author?.localizedCaseInsensitiveContains(term) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            if includeLibrary, !term.isEmpty {
                sectionHeader("In your Library")
                if libraryMatches.isEmpty {
                    Text("No saved shows match “\(term)”.")
                        .font(Typo.caption)
                        .foregroundStyle(theme.textMuted)
                        .padding(.bottom, Space.s)
                } else {
                    ForEach(libraryMatches) { show in
                        NavigationLink(value: Route.show(show)) { ShowListRow(show: show, hasNew: app.hasNewEpisode(show)) }
                            .buttonStyle(TileStyle())
                            .accessibilityIdentifier("libraryMatch")
                    }
                }
                sectionHeader("Find new shows")
                    .padding(.top, Space.l)
            }
            directory
        }
        .onChange(of: app.search.state) { _, state in
            guard let message = Self.announcement(for: state) else { return }
            AccessibilityNotification.Announcement(message).post()
        }
    }

    /// What VoiceOver says when a search settles (nothing while idle or loading).
    static func announcement(for state: SearchModel.State) -> String? {
        switch state {
        case .idle, .loading: nil
        case .results(let results): results.count == 1 ? "1 show found" : "\(results.count) shows found"
        case .empty: "No shows found"
        case .failed: "Couldn’t search"
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Typo.eyebrow).tracking(1.2).textCase(.uppercase)
            .foregroundStyle(theme.textMuted)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var directory: some View {
        let model = app.search
        switch model.state {
        case .idle:
            Text(includeLibrary ? "Type to filter your shows and find new ones." : "Search by show name, host, or topic.")
                .font(Typo.caption)
                .foregroundStyle(theme.textMuted)
                .padding(.top, Space.xs)
        case .loading:
            HStack(spacing: Space.m) {
                ProgressView().tint(theme.text)
                Text("Searching…").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            .padding(.top, Space.l)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("searchLoading")
        case .empty(let term):
            StateMessage(title: "No shows found", message: "Nothing matched “\(term)”. Try another spelling or a shorter name.", systemImage: "questionmark")
                .padding(.horizontal, -Space.xxl)
        case .failed(let message):
            StateMessage(title: "Couldn’t search", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                model.retry()
            }
            .padding(.horizontal, -Space.xxl)
        case .results(let results):
            LazyVStack(spacing: Space.xs) {
                ForEach(results) { result in
                    NavigationLink(value: Route.show(result.show)) {
                        SearchRow(result: result, subscribed: app.isSubscribed(result.show))
                    }
                    .buttonStyle(RowStyle())
                }
            }
            .padding(.horizontal, -Space.s)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("searchResults")
        }
    }
}

struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    var placeholder = "Shows, hosts, topics"
    var onSubmit: () -> Void = {}
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(theme.textMuted)
                .accessibilityHidden(true)
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(theme.textMuted))
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
                .accessibilityAddTraits(.isHeader)
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
