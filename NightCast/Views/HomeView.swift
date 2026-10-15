import NightCastCore
import SwiftUI

/// Home: three swipeable pages (New · Library · Explore) once the Library has
/// shows; just the Library before that, so a first launch has one clear action.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            if model.library.subscriptions.isEmpty {
                LibraryView()
            } else {
                PageDots(selection: $model.homePage)
                TabView(selection: $model.homePage) {
                    NewEpisodesView().tag(HomePage.new)
                    LibraryView().tag(HomePage.library)
                    ExploreView().tag(HomePage.explore)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background { ScreenBackground() }
        .sensoryFeedback(.selection, trigger: model.homePage)
    }
}

/// Three page dots; the current page is a longer pill. Each dot is a 44 pt target.
struct PageDots: View {
    @Binding var selection: HomePage
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomePage.allCases, id: \.self) { page in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) { selection = page }
                } label: {
                    Capsule()
                        .fill(page == selection ? theme.text : theme.textMuted.opacity(0.45))
                        .frame(width: page == selection ? 22 : 8, height: 8)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
                .accessibilityAddTraits(page == selection ? .isSelected : [])
                .accessibilityIdentifier("pageDot-\(page.title)")
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: selection)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pages")
    }
}

/// Large page title shared by the home pages.
struct PageTitle: View {
    let title: String
    var subtitle: String?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(Typo.display)
                .foregroundStyle(theme.text)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
            }
        }
    }
}

// MARK: - New

/// Left page: the newest episodes from Library shows, newest first, by day.
struct NewEpisodesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                PageTitle(title: "New", subtitle: "Latest episodes from your shows")
                    .padding(.top, Space.s)
                    .padding(.bottom, Space.l)
                content
            }
            .padding(.horizontal, Space.xl)
            .padding(.bottom, Space.xxxl)
        }
        .scrollIndicators(.hidden)
        .refreshable { await model.refreshLatest(force: true) }
        .task(id: model.library.subscriptions.map(\.id)) { await model.refreshLatest() }
    }

    @ViewBuilder
    private var content: some View {
        let groups = LatestEpisodes.byDay(model.latest)
        if groups.isEmpty {
            switch model.latestPhase {
            case .idle, .loading:
                HStack(spacing: Space.m) {
                    ProgressView().tint(theme.text)
                    Text("Checking your shows…").font(Typo.caption).foregroundStyle(theme.textMuted)
                }
                .padding(.top, Space.xl)
                .accessibilityElement(children: .combine)
            case .failed(let message):
                StateMessage(title: "Couldn’t load new episodes", message: message, systemImage: "wifi.exclamationmark", actionTitle: "Try again") {
                    Task { await model.refreshLatest(force: true) }
                }
                .padding(.horizontal, -Space.xxl)
            case .loaded:
                StateMessage(title: "All quiet", message: "Nothing new from your shows in the last 30 days.", systemImage: "moon.zzz")
                    .padding(.horizontal, -Space.xxl)
            }
        } else {
            ForEach(groups, id: \.day) { group in
                Text(Self.dayLabel(group.day))
                    .font(Typo.eyebrow)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.textMuted)
                    .padding(.top, Space.l)
                    .padding(.bottom, Space.xs)
                    .accessibilityAddTraits(.isHeader)
                ForEach(group.episodes) { episode in
                    Button { model.play(episode) } label: {
                        LatestRow(
                            episode: episode,
                            position: model.position(for: episode),
                            isPlaying: model.player.episode?.id == episode.id && model.player.isPlaying
                        )
                    }
                    .buttonStyle(RowStyle())
                    .contextMenu { EpisodeMenu(episode: episode) }
                    .accessibilityIdentifier("latestRow")
                }
            }
        }
    }

    static func dayLabel(_ day: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: day, to: calendar.startOfDay(for: now)).day, days < 7 {
            return day.formatted(.dateTime.weekday(.wide))
        }
        let sameYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year(sameYear ? .omitted : .defaultDigits))
    }
}

private struct LatestRow: View {
    let episode: Episode
    let position: PlaybackPosition?
    let isPlaying: Bool
    @Environment(\.theme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: Space.m) {
            if !typeSize.isAccessibilitySize {
                ArtworkView(url: episode.artworkURL, cornerRadius: 10, title: episode.showTitle)
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(Typo.headline)
                    .foregroundStyle(position?.completed == true ? theme.textMuted : theme.text)
                    .lineLimit(typeSize.isAccessibilitySize ? 4 : 2)
                    .multilineTextAlignment(.leading)
                Text(meta)
                    .font(Typo.caption)
                    .foregroundStyle(theme.textMuted)
                    .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
            }
            Spacer(minLength: Space.s)
            ProgressPlayGlyph(fraction: position?.fraction ?? 0, isPlaying: isPlaying)
        }
        .padding(.vertical, Space.s)
        .padding(.horizontal, Space.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(episode.title), \(episode.showTitle)")
        .accessibilityValue(meta)
        .accessibilityAddTraits(.isButton)
    }

    private var meta: String {
        var parts = [episode.showTitle]
        let duration = position?.duration ?? episode.duration
        if position?.completed == true {
            parts.append("Played")
        } else if let position, position.seconds > 5, let duration, duration > 0 {
            parts.append("\(TimeFormat.duration(max(0, duration - position.seconds))) left")
        } else if let duration {
            parts.append(TimeFormat.duration(duration))
        }
        return parts.joined(separator: " · ")
    }
}
