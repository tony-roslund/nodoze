import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(nsImage: EyesIconFactory.make(enabled: model.sleepDisabled, busy: model.isBusy))
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
        .frame(width: 390)
    }
}
