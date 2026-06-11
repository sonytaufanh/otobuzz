# OtoBuzz - Play Store Listing Assets

## Required Graphics

### App Icon
- **Hi-res icon**: 512 x 512 px (PNG, 32-bit, alpha)
- Already generated via `flutter_launcher_icons`

### Feature Graphic
- **Size**: 1024 x 500 px (JPG or PNG, no alpha)
- Used as the banner at the top of the Play Store listing
- Suggested: Show app name + tagline with fleet/vehicle imagery

### Screenshots (minimum 2, recommended 4-8)
- **Phone**: minimum 320px, maximum 3840px on the longest side
- **Aspect ratio**: 16:9 or 9:16

#### Recommended Screenshots:
1. **Home/Dashboard** - Fleet overview with vehicle list and health scores
2. **Input KM** - Daily kilometer input screen
3. **Maintenance Schedule** - Upcoming and overdue maintenance items
4. **Vehicle Detail** - Individual vehicle page with all info
5. **Fuel Tracking** - BBM recording screen
6. **Cost Report** - Monthly/yearly cost analysis
7. **Analytics** - Fleet analytics dashboard
8. **Notifications** - Maintenance reminder notification

### How to Capture Screenshots
1. Use an emulator with Pixel 6 or similar device profile
2. Set device to Indonesian locale
3. Pre-populate with sample data for appealing screenshots
4. Use `flutter screenshot` command or Android Studio
5. Recommended: Use a screenshot framing tool (e.g., screenshots.pro, AppMockUp)

## Store Listing Text

| File | Purpose | Character Limit |
|------|---------|-----------------|
| `title.txt` | App name on Play Store | 30 chars |
| `short_description.txt` | Brief description shown in search | 80 chars |
| `full_description.txt` | Full app description | 4000 chars |

## Content Rating
- Apply for content rating via Google Play Console
- OtoBuzz should qualify for "Everyone" rating (no objectionable content)

## Categorization
- **Category**: Auto & Vehicles
- **Tags**: fleet management, vehicle maintenance, service reminder

## Release Checklist
- [ ] Feature graphic (1024x500) created
- [ ] Minimum 4 screenshots captured
- [ ] Content rating questionnaire completed
- [ ] Privacy policy URL hosted and linked
- [ ] App signing key uploaded to Play Console
- [ ] Target API level meets Play Store requirements
- [ ] App tested on multiple device sizes
