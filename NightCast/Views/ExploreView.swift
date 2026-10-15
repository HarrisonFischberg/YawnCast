import NightCastCore
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
        .refreshable { await model.loadExplore(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.loadExplore() }
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
                    }
                }
            }
        }
    }
}

/// Tappable search field look-alike that opens Search.
struct SearchCapsule: View {
    let action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s) {
                Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .bold))
                Text("Shows, hosts, topics")
                Spacer()
            }
            .font(Typo.headline)
            .foregroundStyle(theme.textMuted)
            .padding(.horizontal, Space.l)
            .frame(minHeight: 52)
            .background(Capsule().fill(theme.surface.opacity(0.85)))
            .overlay(Capsule().strokeBorder(theme.border, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search podcasts")
        .accessibilityIdentifier("exploreSearch")
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
        .foregroundStyle(theme.onAccent)
        .padding(.horizontal, Space.l)
        .frame(minHeight: 44)
        .background(Capsule().fill(theme.accent))
        .accessibilityElement(children: .combine)
    }
}

/// Browse card: icon and name on a softly tinted plate.
struct CategoryCard: View {
    let category: PodcastCategory
    let index: Int
    @Environment(\.theme) private var theme

    /// A gentle, evenly spread hue per card; low saturation so cards don't shout.
    private var tint: Color {
        Color(hue: (Double(index) * 0.61803398875).truncatingRemainder(dividingBy: 1), saturation: 0.45,
              brightness: theme.colorScheme == .dark ? 0.55 : 0.85)
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
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
                content
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
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
            HStack(spacing: Space.m) {
                ProgressView().tint(theme.text)
                Text("Loading \(category.name)…").font(Typo.caption).foregroundStyle(theme.textMuted)
            }
            .accessibilityElement(children: .combine)
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
                    ForEach(shows) { result in
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
            if shows.isEmpty { phase = .failed(SearchModel.message(for: error)) }
        }
    }
}

/// Wraps chips onto as many lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    nonisolated init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    nonisolated func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, width), height: y + rowHeight)
    }

    nonisolated func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
