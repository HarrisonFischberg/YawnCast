import SwiftUI

/// Hidden test-build screen with one toggle per Evolve experiment.
/// Reached by long-pressing the version line at the bottom of Themes; never shown from the App Store.
struct ExperimentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var states: [String: Bool] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if Experiment.allCases.isEmpty {
                        Text("No experiments in this build.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Experiment.allCases) { experiment in
                        Toggle(experiment.title, isOn: binding(for: experiment))
                            .accessibilityIdentifier("experiment-\(experiment.key)")
                    }
                } footer: {
                    Text("Changes apply the next time a screen opens. Launch with -evolve_all YES to turn everything on.")
                }
                Section {
                    Button("Turn all on") {
                        Experiments.setAll(true)
                        reload()
                    }
                    Button("Reset", role: .destructive) {
                        Experiments.reset()
                        reload()
                    }
                }
            }
            .navigationTitle("Experiments")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        // A plain system screen: the app's theme tint is too dark against the stock list.
        .tint(Color.accentColor)
        .preferredColorScheme(.dark)
        .onAppear(perform: reload)
    }

    private func binding(for experiment: Experiment) -> Binding<Bool> {
        Binding {
            states[experiment.key] ?? false
        } set: { on in
            Experiments.set(experiment, on)
            states[experiment.key] = on
        }
    }

    private func reload() {
        states = Dictionary(uniqueKeysWithValues: Experiment.allCases.map { ($0.key, Experiments.isOn($0)) })
    }
}
