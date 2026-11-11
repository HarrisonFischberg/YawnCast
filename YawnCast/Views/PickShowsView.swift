import YawnCastCore
import SwiftUI

/// First launch, step 3: the top 10 shows in ten topics. Pick up to 10 and they
/// go straight into the Library, so Home opens with shows instead of an empty page.
struct PickShowsView: View {
    static let limit = 10
    /// Apple Podcasts genres (top charts), plus a topic search for AI, which has no genre.
    static let topics: [PodcastCategory] = [
        PodcastCategory(id: "genre-1487", name: "History", symbol: "scroll", source: .genre("1487")),
        PodcastCategory(id: "genre-1527", name: "Politics", symbol: "building.columns", source: .genre("1527")),
        PodcastCategory(id: "genre-1306", name: "Cooking", symbol: "fork.knife", source: .genre("1306")),
        PodcastCategory(id: "topic-artificial intelligence", name: "AI", symbol: "sparkles", source: .search("artificial intelligence")),
        PodcastCategory(id: "genre-1518", name: "Medicine", symbol: "cross.case", source: .genre("1518")),
        PodcastCategory(id: "genre-1318", name: "Tech", symbol: "cpu", source: .genre("1318")),
        PodcastCategory(id: "genre-1459", name: "Fashion", symbol: "tshirt", source: .genre("1459")),
        PodcastCategory(id: "genre-1489", name: "News", symbol: "newspaper", source: .genre("1489")),
        PodcastCategory(id: "genre-1324", name: "Society & Culture", symbol: "person.3", source: .genre("1324")),
        PodcastCategory(id: "genre-1533", name: "Science", symbol: "atom", source: .genre("1533")),
    ]

    let onFinish: () -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @State private var picked: [Show] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Step 3 of 3")
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                Spacer()
                Button("Skip", action: onFinish)
                    .font(Typo.headline)
                    .foregroundStyle(theme.textMuted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("skipPicker")
            }
            .padding(.horizontal, Space.xxl)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text("Select your 10 podcasts of interest")
                            .font(Typo.playerTitle)
                            .foregroundStyle(theme.text)
                            .accessibilityAddTraits(.isHeader)
                        Text("\(picked.count) of \(Self.limit) picked")
                            .font(Typo.caption)
                            .foregroundStyle(theme.textMuted)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, Space.xxl)
                    ForEach(Self.topics) { topic in
                        TopicShelf(topic: topic, picked: $picked)
                    }
                }
                .padding(.vertical, Space.l)
            }
            .scrollIndicators(.hidden)

            Button {
                for show in picked where !model.isSubscribed(show) { model.toggleSubscription(show) }
                onFinish()
            } label: {
                Text(picked.isEmpty ? "Pick a few shows" : picked.count == 1 ? "Add 1 show" : "Add \(picked.count) shows")
                    .font(Typo.headline)
                    .padding(.vertical, Space.l)
            }
            .buttonStyle(.capsuleKey(.primary))
            .fixedSize(horizontal: false, vertical: true)
            .disabled(picked.isEmpty)
            .padding(.horizontal, Space.xxl)
            .accessibilityIdentifier("addPicked")
        }
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background { ScreenBackground() }
        .sensoryFeedback(.selection, trigger: picked.count)
    }
}

/// One topic: its name and a sideways row of its top 10 shows.
private struct TopicShelf: View {
    let topic: PodcastCategory
    @Binding var picked: [Show]
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme
    @State private var shows: [DirectoryResult]?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Label(topic.name, systemImage: topic.symbol)
                .font(Typo.headline)
                .foregroundStyle(theme.text)
                .padding(.horizontal, Space.xxl)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: Space.m) {
                    if let shows {
                        if shows.isEmpty {
                            Text("Couldn’t load these right now.")
                                .font(Typo.caption)
                                .foregroundStyle(theme.textMuted)
                        }
                        ForEach(shows) { result in tile(result.show) }
                    } else {
                        ForEach(0..<4, id: \.self) { _ in PlaceholderTile().frame(width: 112) }
                    }
                }
                .padding(.horizontal, Space.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            guard shows == nil else { return }
            shows = Array(((try? await model.shows(in: topic)) ?? []).prefix(PickShowsView.limit))
        }
    }

    private func tile(_ show: Show) -> some View {
        let isPicked = picked.contains(show)
        return Button {
            if isPicked { picked.removeAll { $0 == show } } else if picked.count < PickShowsView.limit { picked.append(show) }
        } label: {
            VStack(alignment: .leading, spacing: Space.xs) {
                ArtworkView(url: show.artworkURL, cornerRadius: Radius.artwork, title: show.title)
                    .frame(width: 112, height: 112)
                    .opacity(isPicked || picked.count < PickShowsView.limit ? 1 : 0.4)
                    .overlay(alignment: .topTrailing) {
                        if isPicked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.text, theme.bg)
                                .padding(Space.xs)
                        }
                    }
                Text(show.title)
                    .font(Typo.caption)
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 112, alignment: .leading)
            .padding(6)
            .paper(seed: show.title.count, fill: theme.surface)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(show.title)
        .accessibilityAddTraits(isPicked ? .isSelected : [])
        .accessibilityIdentifier("pickShow")
    }
}
