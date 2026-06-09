# OtoBuzz App Icon Assets

## Required Files

### `app_icon.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparency
- **Description**: Full app icon with blue (#1565C0) background and white vehicle + wrench logo
- Used for iOS app icon and Android legacy icon

### `app_icon_foreground.png`
- **Size**: 1024x1024 pixels (with safe zone — keep content within center 66%)
- **Format**: PNG with transparency (transparent background)
- **Description**: White vehicle + wrench logo only (no background) for Android adaptive icons
- The background color (#1565C0) is set separately in the config

## Generation

After placing the PNG files in this directory, run:

```bash
dart run flutter_launcher_icons
```

## Design Specs

- Primary Blue: #1565C0
- Dark Blue: #0D47A1
- Icon Content: Stylized car silhouette with crossed wrenches
- Style: Simple, flat, recognizable at small sizes
