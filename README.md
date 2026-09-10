# RightMouseUtility

Create TXT, Markdown, and Word files from Finder's right-click menu.

- Right-click a folder background to create a file there.
- Right-click a folder to create a file inside it.
- Right-click a file to create a file beside it.
- Names start at `Untitled.txt`, `Untitled.md`, or `Untitled.docx`. Existing names get a number.
- New files are selected in Finder. Existing files are never overwritten.
- TXT and Markdown files start empty. Word documents copy the bundled template.

## Build

Requires macOS 13 or later and Xcode command line tools. No dependencies.

```sh
swift test
bash scripts/build.sh
open build/RightMouseUtility.app
```

The app includes a Finder Sync extension. The default build uses a local ad hoc signature. For distribution, use a Developer ID identity and notarize the app.

```sh
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" bash scripts/build.sh
```

The build targets the current Mac. Set `ARCH=arm64` or `ARCH=x86_64` to change it.

## Use

1. Keep the app in a stable location, such as `/Applications`.
2. Open it and click **Finder Extension Settings**.
3. Enable **RightMouseUtility**. On macOS 26, it appears under **File Providers**.
4. Open a normal folder in Finder. Right-click and choose a file type.

The app also has buttons to choose a folder and create a file directly. macOS may ask for access to protected folders. Allow access to create files there. Read-only folders show an error. Virtual locations, such as Recents, are not supported. Multiple selections do not show these menu items. App bundles are treated as files.

If the menu is missing, check the extension setting and reopen the Finder window. Rebuilding or moving the app may require enabling the extension again.

## Design

The sandboxed Finder extension sends a typed URL request to its containing app. The app writes the file with the user's normal permissions. It does not require Full Disk Access, Accessibility access, a server, or a background login item. File creation uses an exclusive write to prevent overwrites, including name races.

`Resources/Empty-DOCX.docx` is the supplied Word template. Each new document is an exact copy of its contents. Replace this file and rebuild to change the template. Word is not required to create a document.

`Resources/Icons` contains the menu icons from TextEdit (TXT), Markdown Preview (Markdown), and Microsoft Word (DOCX). The extension bundles these icons.

`Sources/Core` contains request parsing and file creation. `Sources/App` contains the native AppKit window. `Sources/FinderExtension` contains the three menu items.

## Validation

Tested on macOS 26.6.2 with Apple silicon.

- Ten unit tests pass, including exact template copies and overwrite protection.
- The app and extension build with warnings treated as errors.
- The app and extension pass code signature verification.
- Finder creates TXT, Markdown, and Word files, including when the app is closed.
- Existing names get a number. Finder selects the new file.
