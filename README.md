# PCX Preview

A native macOS application for viewing and converting PCX image files.

PCX Preview provides a simple Mac interface for opening legacy PCX images, inspecting them at different zoom levels, and exporting them to modern image formats. The application is written in Swift and SwiftUI and includes its own PCX decoding support.

## Features

- Open and display `.pcx` image files
- Support for indexed-color and true-color PCX images
- PCX run-length encoding (RLE) decoding
- Scrollable image viewing
- Adjustable zoom
- Zoom to Fit
- Actual Size viewing
- Export images as:
  - PNG
  - JPEG
  - BMP
- Print PCX images directly from macOS
- Native macOS document-based interface
- No external dependencies

PCX Preview is intentionally a viewer and converter rather than an image editor. PCX files are opened read-only and are not modified by the application.

## Requirements

- macOS 26.0 or later
- Xcode 26 or later to build from source

## Building

Clone the repository:

```bash
git clone https://github.com/foxrunlabs/pcxpreview.git
cd pcxpreview
```

Open the Xcode project:

```bash
open PCXPreview.xcodeproj
```

Select the **PCXPreview** scheme and build and run the application.

No third-party frameworks or packages are required.

## Usage

### Opening a PCX Image

Open PCX Preview and select **File → Open**, or open a `.pcx` file from Finder after associating the file type with PCX Preview.

The application registers `.pcx` as an image document type with macOS.

### Viewing

Use the application's zoom controls to change the displayed image size.

- **Zoom to Fit** scales the image to fit the available window.
- **Actual Size** displays the image at its native pixel dimensions.
- Other zoom levels allow closer inspection of the image.

Images larger than the window can be navigated using the scrollable image view.

### Exporting

PCX images can be converted to modern formats using the application's export commands.

Supported export formats are:

- **PNG** — lossless and generally the best choice for preserving PCX graphics
- **JPEG** — useful for photographic images where smaller file size is preferred
- **BMP** — useful when an uncompressed bitmap format is required

Exporting creates a new image file and does not alter the original PCX document.

## About PCX

PCX (PiCture eXchange) is a raster image format originally developed by ZSoft for PC Paintbrush. It was widely used by DOS-era graphics applications and games but has largely been replaced by formats such as PNG and JPEG.

PCX images commonly use run-length encoding (RLE) for compression and may represent either palette-indexed or direct-color image data.

PCX Preview is intended to make these older images readily accessible on modern macOS systems without requiring legacy graphics software.

## Implementation

PCX Preview is a native Swift application built using SwiftUI.

The application uses SwiftUI's document architecture to integrate PCX files with the standard macOS document workflow. PCX data is decoded by the application and converted into a representation that can be displayed using native macOS graphics APIs.

The project registers its own Uniform Type Identifier for PCX files:

```text
net.thefoxrun.PCXPreview.pcx
```

with the `.pcx` filename extension and `public.image` conformance.

## Project Status

PCX Preview is a small utility developed primarily to provide native macOS support for viewing legacy PCX images.

Bug reports and improvements are welcome through the repository's Issues page.

## Contributing

Contributions are welcome.

To contribute:

1. Fork the repository.
2. Create a feature or bug-fix branch.
3. Make and test your changes.
4. Submit a pull request describing the change.

When adding or modifying PCX decoding functionality, test against files using different image dimensions, palettes, color depths, and RLE patterns where possible.

## License

QBPlay is available under the [MIT License](LICENSE).

Copyright © 2026 Ryan Clarke
