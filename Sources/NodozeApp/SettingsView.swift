import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(nsImage: EyesIconFactory.make(
                    enabled: model.sleepDisabled,
                    busy: model.isBusy,
                    style: model.menuBarIconStyle
                ))
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 42, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text("nodoze")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text(model.sleepDisabled ? "Keeping this Mac awake with the lid closed." : "Lid-close sleep is normal.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Open at login", isOn: Binding(
                    get: { model.openAtLogin },
                    set: { model.setOpenAtLogin($0) }
                ))

                Toggle("Allow display to sleep while nodoze is active", isOn: Binding(
                    get: { model.allowDisplaySleepWhileActive },
                    set: { model.setAllowDisplaySleepWhileActive($0) }
                ))

                Picker("Menu bar icon", selection: Binding(
                    get: { model.menuBarIconStyle },
                    set: { model.setMenuBarIconStyle($0) }
                )) {
                    Text("Full Color").tag(MenuBarIconStyle.fullColor)
                    Text("Monochrome").tag(MenuBarIconStyle.monochrome)
                }
                .pickerStyle(.radioGroup)

                Toggle("Keep awake while agents are running", isOn: Binding(
                    get: { model.keepActiveUntilAgentsFinish },
                    set: { model.setKeepActiveUntilAgentsFinish($0) }
                ))

                if model.keepActiveUntilAgentsFinish {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("nodoze watches common agent tools and turns itself off after they have been idle for the selected duration.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Stepper(
                            "Turn off after \(model.agentIdleGraceMinutes) min idle",
                            value: Binding(
                                get: { model.agentIdleGraceMinutes },
                                set: { model.setAgentIdleGraceMinutes($0) }
                            ),
                            in: 1...120
                        )

                        DisclosureGroup("Advanced") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Apps to watch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 18, verticalSpacing: 8) {
                                    GridRow {
                                        Toggle("Codex", isOn: Binding(
                                            get: { model.monitorCodex },
                                            set: { model.setMonitorCodex($0) }
                                        ))
                                        Toggle("Claude Code", isOn: Binding(
                                            get: { model.monitorClaudeCode },
                                            set: { model.setMonitorClaudeCode($0) }
                                        ))
                                    }

                                    GridRow {
                                        Toggle("Cursor", isOn: Binding(
                                            get: { model.monitorCursor },
                                            set: { model.setMonitorCursor($0) }
                                        ))
                                        Toggle("Terminal CLIs", isOn: Binding(
                                            get: { model.monitorTerminalCLIs },
                                            set: { model.setMonitorTerminalCLIs($0) }
                                        ))
                                    }

                                    GridRow {
                                        Toggle("Conductor", isOn: Binding(
                                            get: { model.monitorConductor },
                                            set: { model.setMonitorConductor($0) }
                                        ))
                                        Toggle("Superset", isOn: Binding(
                                            get: { model.monitorSuperset },
                                            set: { model.setMonitorSuperset($0) }
                                        ))
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    TextField("Custom process names, comma separated", text: Binding(
                                        get: { model.customAgentProcessNames },
                                        set: { model.setCustomAgentProcessNames($0) }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    Text("Use custom names only for niche agent tools that are not listed above.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 6)
                        }

                        Text(model.agentActivitySummary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 18)
                }

                Toggle("Check for updates automatically", isOn: $model.automaticUpdateChecks)
            }
            .toggleStyle(.checkbox)

            HStack(spacing: 10) {
                Button("Check for Updates") {
                    model.checkForUpdates()
                }
                .keyboardShortcut("u", modifiers: .command)

                Button("About") {
                    model.onAbout()
                }

                Spacer()
            }

            Text(model.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        }
        .padding(22)
        .frame(width: 460)
    }
}
