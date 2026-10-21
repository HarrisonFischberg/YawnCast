import SwiftUI

/// Hidden Feature flags screen: one toggle per shipped feature, plus any Evolve
/// experiments in test builds. Reached by pressing and holding the version line at the
/// bottom of Themes, then tapping Feature flags.
struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var states: [String: Bool] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if available.isEmpty {
                        Text("No feature flags in this build.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(available) { experiment in
                        Toggle(experiment.title, isOn: binding(for: experiment))
                            .accessibilityIdentifier("experiment-\(experiment.key)")
                    }
                } footer: {
                    Text("Shipped features start on. Changes apply the next time a screen opens. Launch with -evolve_all YES to turn everything on.")
                }
                Section {
                    Button("Turn all on") {
                        Experiments.setAll(true)
                        reload()
                    }
                    Button("Reset to defaults", role: .destructive) {
                        Experiments.reset()
                        reload()
                    }
                }
            }
            .navigationTitle("Feature flags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        // A plain system screen: the app's theme tint is too dark against the stock list.
        .tint(Color.accentColor)
        .preferredColorScheme(.dark)
        .onAppear(perform: reload)
    }

    private var available: [Experiment] { Experiment.allCases.filter(Experiments.isAvailable) }

    private func binding(for experiment: Experiment) -> Binding<Bool> {
        Binding {
            states[experiment.key] ?? false
        } set: { on in
            Experiments.set(experiment, on)
            states[experiment.key] = on
        }
    }

    private func reload() {
        states = Dictionary(uniqueKeysWithValues: available.map { ($0.key, Experiments.isOn($0)) })
    }
}
