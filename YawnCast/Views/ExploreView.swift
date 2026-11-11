import YawnCastCore
import SwiftUI

/// Right home page: search, your interests (from what you've saved), top
/// picks, every category, then "because you like" rows.
struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    private var showColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Space.xl, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    private var cardColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Space.m), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        SearchablePage(page: .explore) {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                PageTitle(title: "Explore", subtitle: "Find shows for every interest")
                    .padding(.top, Space.s)

                SearchCapsule { model.openSearch() }

                if !model.interests.isEmpty {
                    section("Your interests") {
                        FlowLayout(spacing: Space.s) {
                            ForEach(model.interests) { category in
                                NavigationLink(value: Route.category(category)) { InterestChip(category: category) }
                                    .buttonStyle(TileStyle())
                                    .accessibilityIdentifier("interest-\(category.name)")
                            }
                        }
                    }
                }

                recommendations(topPicksOnly: true)

                section("Browse") {
                    LazyVGrid(columns: cardColumns, spacing: Space.m) {
                        ForEach(Array(PodcastCategory.browse.enumerated()), id: \.element.id) { index, category in
                            NavigationLink(value: Route.category(category)) { CategoryCard(category: category, index: index) }
                                .buttonStyle(TileStyle())
                                .accessibilityIdentifier("category-\(category.name)")
                        }
                    }
                }

                recommendations(topPicksOnly: false)

                Text("Suggestions use the Apple Podcasts genres and titles of the shows you save, Apple’s public charts, and directory search. Nothing about you is stored or sent anywhere else.")
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .dockAware()
        .refreshable { await model.loadExplore(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.loadExplore() }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Text(title)
                .font(Typo.title)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    @ViewBuilder
    private func recommendations(topPicksOnly: Bool) -> some View {
        let sections = model.explore.filter { ($0.genre.id == Recommender.topPicksID) == topPicksOnly }
        if topPicksOnly, model.explore.isEmpty {
            switch model.explorePhase {
            case .idle, .loading:
                HStack(spacing: Space.m) {
                    ProgressView().tint(theme.text)
                    Text("Finding shows you might like…").font(Typo.caption).foregroundStyle(theme.textMuted)
                }
                .accessibilityElement(children: .combine)
            case .failed(let message):
                StateMessage(title: "Suggestions didn’t load", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                    Task { await model.loadExplore(force: true) }
                }
                .padding(.horizontal, -Space.xxl)
            case .loaded:
                EmptyView()
            }
        }
        ForEach(sections) { row in
            section(row.genre.id == Recommender.topPicksID ? "Top picks for you" : "Because you like \(row.genre.name)") {
                LazyVGrid(columns: showColumns, alignment: .leading, spacing: Space.xxl) {
                    ForEach(row.shows) { recommendation in
                        NavigationLink(value: Route.show(recommendation.result.show)) {
                            ShowTile(show: recommendation.result.show)
                        }
                        .buttonStyle(TileStyle())
                        .modifier(QuickAdd(show: recommendation.result.show))
                    }
                }
            }
        }
    }
}

/// A + in the tile's corner that saves the show in one tap (hidden once saved).
struct QuickAdd: ViewModifier {
    let show: Show
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            if !model.isSubscribed(show) {
                Button { model.add(show) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(theme.onAccent, theme.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Add \(show.title) to Library")
                .accessibilityIdentifier("addShow")
            }
        }
    }
}

/// Tappable search field look-alike that opens Search.
struct SearchCapsule: View {
    var placeholder = "Shows, hosts, topics"
    var identifier = "exploreSearch"
    let action: () -> Void
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s) {
                Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .bold))
                // One line always; at accessibility sizes just "Search", so the bar
                // doesn't grow into a four-line pill (review 2026-10-19, P1).
                Text(typeSize.isAccessibilitySize ? "Search" : placeholder)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer()
            }
            .font(.system(.body, weight: .medium))
            .foregroundStyle(theme.textMuted)
            .padding(.horizontal, Space.l)
            .frame(minHeight: 52)
            .nightGlass(in: Capsule(), interactive: true) {
                Capsule().fill(theme.surface.opacity(0.85)).overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(placeholder)
        .accessibilityIdentifier(identifier)
    }
}

/// Rounded chip for an interest.
private struct InterestChip: View {
    let category: PodcastCategory
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: category.symbol)
            Text(category.name)
        }
        .font(Typo.headline)
        .foregroundStyle(theme.text)
        .padding(.horizontal, Space.l)
        .frame(minHeight: 44)
        // The accent belongs to the Moon key; chips are quietly filled.
        .nightGlass(in: Capsule(), interactive: true) { Capsule().fill(theme.surface) }
        .accessibilityElement(children: .combine)
    }
}

/// Browse card: icon and name on a softly tinted plate.
struct CategoryCard: View {
    let category: PodcastCategory
    let index: Int
    @Environment(\.theme) private var theme

    /// The icon plate: the look's own muted ink (no rainbow hues, which no look uses).
    private var tint: Color {
        theme.warmOnly ? theme.accent : theme.textMuted
    }

    var body: some View {
        HStack(spacing: Space.m) {
            Image(systemName: category.symbol)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(Circle().fill(tint.opacity(0.45)))
            Text(category.name)
                .font(Typo.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.text)
        .padding(Space.m)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.28), theme.surface.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.border, lineWidth: 1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// A category's shows: its genre's top chart, or a topic search.
struct CategoryView: View {
    let category: PodcastCategory
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var shows: [DirectoryResult] = []
    @State private var phase: LoadPhase = .idle
    @State private var sort = CategorySort.popular

    /// Sorts the data supports: chart order, newest episode date, the chart's
    /// quieter end (as "Hidden gems"), and title.
    enum CategorySort: String, CaseIterable {
        case popular = "Most Popular", newest = "Newest", hiddenGems = "Hidden Gems", title = "A–Z"
    }

    private var sorted: [DirectoryResult] {
        switch sort {
        case .popular: shows
        case .newest: shows.sorted { ($0.latestRelease ?? .distantPast) > ($1.latestRelease ?? .distantPast) }
        case .hiddenGems: shows.reversed()
        case .title: shows.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Space.xl, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                HStack(spacing: Space.m) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(theme.accent)
                    Text(category.name)
                        .font(Typo.display)
                        .textCase(Typo.titleCase)
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
                Picker("Sort", selection: $sort) {
                    ForEach(CategorySort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(theme.text)
                .accessibilityIdentifier("categorySort")
                content
            }
            // Fill the width from the first frame (the loading state alone is narrow).
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .dockAware()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { ScreenBackground() }
        .refreshable { await load(force: true) }
        .task { await load(force: false) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.bg, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle, .loading:
            // Placeholder tiles in the final layout, so nothing jumps when shows arrive.
            LazyVGrid(columns: columns, alignment: .leading, spacing: Space.xxl) {
                ForEach(0..<6, id: \.self) { _ in PlaceholderTile() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading \(category.name)")
        case .failed(let message):
            StateMessage(title: "Couldn’t load \(category.name)", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                Task { await load(force: true) }
            }
            .padding(.horizontal, -Space.xxl)
        case .loaded:
            if shows.isEmpty {
                StateMessage(title: "Nothing here yet", message: "Try Search for something more specific.", systemImage: "tray")
                    .padding(.horizontal, -Space.xxl)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: Space.xxl) {
                    ForEach(sorted) { result in
                        NavigationLink(value: Route.show(result.show)) {
                            ShowTile(show: result.show)
                                .overlay(alignment: .topLeading) {
                                    if model.isSubscribed(result.show) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(theme.onAccent, theme.accent)
                                            .padding(6)
                                            .accessibilityLabel("In your Library")
                                    }
                                }
                        }
                        .buttonStyle(TileStyle())
                        .modifier(QuickAdd(show: result.show))
                    }
                }
            }
        }
    }

    private func load(force: Bool) async {
        if shows.isEmpty { phase = .loading }
        do {
            shows = try await model.shows(in: category, force: force)
            phase = .loaded
        } catch is CancellationError {
            return
        } catch {
            if shows.isEmpty { phase = .failed(SearchModel.message(for: error, fallback: "Something went wrong. Try again.")) }
        }
    }
}

/// Wraps chips onto as many lines as needed.
///
/// Sizing and placing share one line-breaking pass at the same width. They
/// used to break separately, sizing at the proposed width but placing within
/// `bounds`, which is only as wide as the widest line and pixel-rounded. A
/// hair of rounding could push a chip onto an extra line that was never
/// measured, so it drew over the section below ("Top picks for you").
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    nonisolated init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    nonisolated func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let placed = frames(for: subviews, width: width)
        let widest = placed.map(\.maxX).max() ?? 0
        let height = placed.map(\.maxY).max() ?? 0
        // Take the whole offered width, so placement breaks lines at the width we measured.
        return CGSize(width: width.isFinite ? width : widest, height: height)
    }

    nonisolated func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = proposal.width ?? bounds.width
        for (subview, frame) in zip(subviews, frames(for: subviews, width: width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    /// Each chip's frame, wrapping to a new line when the next one won't fit.
    private nonisolated func frames(for subviews: Subviews, width: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Half a point of slack, so float rounding never forces a wrap.
            if x > 0, x + size.width > width + 0.5 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return frames
    }
}

/// A quiet stand-in for a show tile while a list loads.
struct PlaceholderTile: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.surface.opacity(0.8))
                .aspectRatio(1, contentMode: .fit)
            Capsule().fill(theme.surface.opacity(0.8)).frame(height: 12)
            Capsule().fill(theme.surface.opacity(0.6)).frame(width: 80, height: 10)
        }
        .opacity(dim ? 0.55 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { dim = true }
        }
    }
}
