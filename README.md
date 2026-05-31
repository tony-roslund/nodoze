# nodoze

nodoze is a tiny macOS menu bar app for keeping a MacBook awake while the lid is closed.

Free and open source under the MIT License.

On Apple Silicon Macs, normal `caffeinate`-style power assertions do not reliably keep a MacBook awake after the lid is closed. nodoze uses `pmset disablesleep` for the lid-closed behavior, then keeps regular macOS power assertions as a visible supplemental signal while the app is active.

When installed with the signed `.pkg`, nodoze adds a tightly scoped sudoers rule that allows admin users to run only these two commands without a repeated password prompt:

```sh
/usr/bin/pmset -a disablesleep 1
/usr/bin/pmset -a disablesleep 0
```

That means the installer asks for normal macOS admin approval once, and the menu bar toggle can turn lid-close sleep prevention on and off after that. The direct `.zip` app build is useful for inspection or manual installation, but the `.pkg` is the supported install path for the passwordless toggle setup.

To verify the real lid-closed mechanism:

```sh
pmset -g | grep SleepDisabled
```

Expected states:

- nodoze on: `SleepDisabled 1`
- nodoze off: `SleepDisabled 0`

Other tools, including agent CLIs, may also create their own `caffeinate` or IOKit assertions. Those can show up in `pmset -g assertions`, but nodoze's core state is the `SleepDisabled` value above.

## App

```sh
swift test
./script/build_and_run.sh --verify
```

The Codex Run action is wired to:

```sh
./script/build_and_run.sh
```

## Website

```sh
cd website
npm install
npm run dev
npm run build
```

The website is a static Vite app and is ready to deploy on Vercel with:

- Root directory: `website`
- Build command: `npm run build`
- Output directory: `dist`

## Installer Release Checklist

1. Create a Developer ID Application certificate.
2. Create a Developer ID Installer certificate.
3. Sign `nodoze.app`.
4. Build a `.pkg` that installs `/Applications/nodoze.app`.
5. Sign, notarize, and staple the `.pkg`.
6. Upload the build and update `https://nodoze.io/appcast.json`.

The release helper signs the app and builds both `.zip` and `.pkg` artifacts:

```sh
./script/package_release.sh
```

To sign and notarize the installer in the same pass:

```sh
INSTALLER_SIGNING_IDENTITY="Developer ID Installer: Anthony Roslund (9456DA7AJR)" \
NOTARY_PROFILE=nodoze-notary-api \
./script/package_release.sh
```

If the Installer certificate is missing, upload `private/DeveloperIDInstaller.certSigningRequest` to Apple Developer as a Developer ID Installer certificate, download the `.cer`, then import it into the login keychain with the matching private key in `private/DeveloperIDInstaller.key`.

## Links

- Website: https://nodoze.io
- Source: https://github.com/tony-roslund/nodoze
- X: https://x.com/tonyroslund

## License

MIT License. See [LICENSE](LICENSE).
