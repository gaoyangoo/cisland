# Versioning

Claus Island follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`).

| Segment | Bump when |
|---------|-----------|
| **MAJOR** | Breaking architecture change, macOS target bump, incompatible API |
| **MINOR** | New module, new feature, significant UI redesign |
| **PATCH** | Bug fixes, color/spacing tweaks, performance improvements |

## Current Version

**1.0.0** — First stable release.

### Release build

```bash
xcodebuild -project cisland.xcodeproj -scheme cisland -configuration Release build

# Package DMG
APP="DerivedData/.../Release/cisland.app"
hdiutil create -volname "Claus Island" -srcfolder "$APP" -ov -format UDZO download/Cisland-1.0.0.dmg
```
