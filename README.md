# nodoze

nodoze is a tiny macOS menu bar app for keeping a MacBook awake while the lid is closed.

Free and open source under the MIT License.

The app toggles the macOS power setting:

```sh
pmset -a disablesleep 1
pmset -a disablesleep 0
```

Because this setting requires administrator privileges, the release installer installs a narrow privileged helper at `/Library/PrivilegedHelperTools/io.nodoze.helper`. The menu bar app only asks that helper to read or toggle `disablesleep`.

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
3. Sign `nodoze.app` and `io.nodoze.helper`.
4. Build a `.pkg` that installs:
   - `/Applications/nodoze.app`
   - `/Library/PrivilegedHelperTools/io.nodoze.helper`
5. Sign, notarize, and staple the `.pkg`.
6. Upload the build and update `https://nodoze.io/appcast.json`.

The release helper signs the app/helper and builds both `.zip` and `.pkg` artifacts:

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
