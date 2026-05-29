# nodoze

nodoze is a tiny macOS menu bar app for keeping a MacBook awake while the lid is closed.

Free and open source under the MIT License.

The app toggles the macOS power setting:

```sh
pmset -a disablesleep 1
pmset -a disablesleep 0
```

Because this setting requires administrator privileges, nodoze prompts through macOS when the toggle changes.

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

## Release Checklist

1. Create a Developer ID Application certificate.
2. Sign `dist/nodoze.app`.
3. Notarize and staple the app.
4. Package a `.dmg` or `.zip`.
5. Upload the build and update `https://nodoze.io/appcast.json`.

The release helper signs and zips the app:

```sh
./script/package_release.sh
```

To notarize in the same pass after storing notary credentials:

```sh
NOTARY_PROFILE=nodoze-notary-api ./script/package_release.sh
```

## Links

- Website: https://nodoze.io
- Source: https://github.com/tony-roslund/nodoze
- X: https://x.com/tonyroslund

## License

MIT License. See [LICENSE](LICENSE).
