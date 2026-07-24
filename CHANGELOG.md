# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial project structure
- `UpdateManager` core class with native + code push support
- `UpdateConfig` configuration model
- `UpdateResult` response model
- `UpdateProgress` progress model
- `UpdateManagerStatus` status enum
- `UpdateType` enum (native, codepush, none)
- `Changelog` model with changelog support
- `PatchInfo` model for Git Tag patches
- `UpdateStateStorage` for persistent state (SharedPreferences)
- `ChangelogService` for fetching changelog from GitHub
- `GitHubTagService` for fetching tags and release notes
- `ChangelogParser` for parsing release notes
- `NativeUpdater` wrapper for flutter_apk_updater
- `CodePushUpdater` wrapper for Shorebird
- `UpdateDialogManager` for showing update dialog
- `DefaultChangelogDialog` default dialog implementation
- `ChangelogHelpers` for custom UI development
- `UpdateLogger` for debugging
- `VersionUtils` for version manipulation

### Features
- **Check Updates**: Check native update + code push simultaneously
- **Priority Logic**: Native update prioritized over code push
- **Changelog**: Display changelog from GitHub Releases (native) and Git Tags (patch)
- **Pending Install**: Save pending native update or patch
- **Custom Dialog**: Flexible dialog customization via `dialogBuilder`
- **Progress Stream**: Real-time progress updates via Stream or callback
- **Status Tracking**: `UpdateManagerStatus` for UI state management
- **Manual Mode**: Code Push manual mode (`auto_update: false` in shorebird.yaml)

### Dependencies
- `flutter_apk_updater`: Native update via GitHub Releases
- `shorebird_code_push`: Code Push via Shorebird
- `shared_preferences`: Persistent storage
- `dio`: HTTP client for GitHub API
- `terminate_restart`: Restart app for patch application
- `package_info_plus`: Get current app version

### Platforms
- Android (Native + Code Push)
- iOS (Code Push only)

---

## [0.0.1] - 2026-07-24

### Added
- Initial release
- Basic update management functionality
- Native update via GitHub Releases
- Code Push via Shorebird
- Changelog support
- Default dialog implementation
- Custom dialog builder
- Documentation (README.md, CHANGELOG.md)

### Known Issues
- Shorebird must be initialized via `shorebird init` before using
- GitHub tag must have release notes for changelog to work
- Native update only available on Android
- Need to set `auto_update: false` in shorebird.yaml for manual mode

### Notes
- This is a private package for TuyulTronik internal use
- Not published to pub.dev yet
- For internal development only

---

## [0.0.1] - Initial Development

### Added
- Project structure created
- All core features implemented
- Testing not yet implemented
- Example app not yet created

### Next Steps
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Create example app
- [ ] Publish to pub.dev (if needed)

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `Added` | New features added |
| `Changed` | Changes to existing features |
| `Deprecated` | Features that will be removed soon |
| `Removed` | Features that are removed |
| `Fixed` | Bug fixes |
| `Security` | Security improvements |

---

## Version History

| Version | Date | Status |
|---------|------|--------|
| 0.0.1 | 2026-07-24 | Development |
| Unreleased | - | In Progress |