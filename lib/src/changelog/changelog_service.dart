import 'package:flutter_apk_updater/flutter_apk_updater.dart';

import '../models/changelog.dart';
import '../models/patch_info.dart';
import 'github_tag_service.dart';

/// Service untuk mengelola changelog dari berbagai sumber
class ChangelogService {
  ChangelogService({
    required this.githubOwner,
    required this.githubRepository,
    this.githubToken,
  }) : _tagService = GitHubTagService();

  final String githubOwner;
  final String githubRepository;
  final String? githubToken;
  final GitHubTagService _tagService;

  /// Ambil changelog dari GitHub Release (native update)
  Future<Changelog?> getNativeChangelog(UpdateInfo info) async {
    if (info.release.releaseNotes.isEmpty) return null;

    return Changelog.fromReleaseNotes(
      version: info.latestVersion,
      releaseNotes: info.release.releaseNotes,
      publishedAt: info.release.publishedAt,
      type: ChangelogType.native,
    );
  }

  /// Ambil changelog dari Git Tag (patch)
  Future<Changelog?> getPatchChangelog(PatchInfo info) async {
    if (info.releaseNotes.isEmpty) return null;

    return Changelog.fromReleaseNotes(
      version: info.version,
      releaseNotes: info.releaseNotes,
      publishedAt: info.publishedAt,
      type: ChangelogType.patch,
      patchVersion: info.patchVersion,
    );
  }

  /// Dapatkan patch terbaru untuk versi tertentu
  Future<PatchInfo?> getLatestPatch(String version) async {
    return _tagService.getLatestPatch(
      owner: githubOwner,
      repository: githubRepository,
      version: version,
      token: githubToken,
    );
  }

  /// Dapatkan semua tag patch untuk versi tertentu
  Future<List<PatchInfo>> getAllPatches(String version) async {
    final tags = await _tagService.getTags(
      owner: githubOwner,
      repository: githubRepository,
      token: githubToken,
    );

    final patchTags = tags
        .where((tag) => tag.isPatch && tag.baseVersion == version)
        .toList();

    final patches = <PatchInfo>[];

    for (final tag in patchTags) {
      final releaseNotes = await _tagService.getReleaseNotesForTag(
        owner: githubOwner,
        repository: githubRepository,
        tag: tag.name,
        token: githubToken,
      );

      patches.add(PatchInfo(
        tagName: tag.name,
        version: version,
        patchVersion: tag.patchNumber,
        releaseNotes: releaseNotes ?? '',
        publishedAt: DateTime.now(),
      ));
    }

    // Sort berdasarkan patch number
    patches.sort((a, b) {
      final aNum = int.tryParse(a.patchVersion) ?? 0;
      final bNum = int.tryParse(b.patchVersion) ?? 0;
      return bNum.compareTo(aNum);
    });

    return patches;
  }
}