import 'package:dio/dio.dart';
import '../models/patch_info.dart';
import '../utils/logger.dart';

/// Model untuk GitHub Tag
class GitHubTag {
  const GitHubTag({
    required this.name,
    required this.commitSha,
    required this.zipballUrl,
    required this.tarballUrl,
  });

  final String name;
  final String commitSha;
  final String zipballUrl;
  final String tarballUrl;

  factory GitHubTag.fromJson(Map<String, dynamic> json) {
    return GitHubTag(
      name: json['name'] as String,
      commitSha: json['commit']['sha'] as String,
      zipballUrl: json['zipball_url'] as String,
      tarballUrl: json['tarball_url'] as String,
    );
  }

  /// Cek apakah tag ini adalah patch
  bool get isPatch => 
      name.contains('-patch') || 
      name.contains('-patch-') ||
      name.contains('.patch');

  /// Extract base version dari tag patch
  /// Contoh: "v1.0.1-patch1" → "1.0.1"
  String get baseVersion {
    var cleaned = name;
    // Hapus awalan 'v' atau 'V'
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }
    // Hapus suffix patch
    if (cleaned.contains('-patch')) {
      cleaned = cleaned.split('-patch')[0];
    }
    if (cleaned.contains('.patch')) {
      cleaned = cleaned.split('.patch')[0];
    }
    return cleaned;
  }

  /// Extract patch number
  /// Contoh: "v1.0.1-patch1" → "1"
  String get patchNumber {
    if (name.contains('-patch')) {
      final parts = name.split('-patch');
      if (parts.length > 1) {
        return parts[1];
      }
    }
    if (name.contains('.patch')) {
      final parts = name.split('.patch');
      if (parts.length > 1) {
        return parts[1];
      }
    }
    return '0';
  }
}

/// Service untuk mengambil data dari GitHub API
class GitHubTagService {
  GitHubTagService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _baseUrl = 'https://api.github.com';

  /// Ambil semua tag dari repository
  Future<List<GitHubTag>> getTags({
    required String owner,
    required String repository,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          if (token != null && token.isNotEmpty) 
            'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.get(
        '$_baseUrl/repos/$owner/$repository/tags',
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GitHubTag.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      UpdateLogger.warning('❌ Error fetching tags: ${e.message}');
      return [];
    } catch (e) {
      UpdateLogger.warning('❌ Unexpected error: $e');
      return [];
    }
  }

  /// Ambil release notes untuk tag tertentu
  Future<String?> getReleaseNotesForTag({
    required String owner,
    required String repository,
    required String tag,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          if (token != null && token.isNotEmpty) 
            'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.get(
        '$_baseUrl/repos/$owner/$repository/releases/tags/$tag',
        options: options,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['body'] as String?;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Tag tidak memiliki release notes
        return null;
      }
      UpdateLogger.warning('❌ Error fetching release notes: ${e.message}');
      return null;
    } catch (e) {
      UpdateLogger.warning('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Dapatkan patch terbaru untuk versi tertentu
  Future<PatchInfo?> getLatestPatch({
    required String owner,
    required String repository,
    required String version,
    String? token,
  }) async {
    final tags = await getTags(
      owner: owner,
      repository: repository,
      token: token,
    );

    // Filter tag yang merupakan patch untuk versi ini
    final patchTags = tags
        .where((tag) => tag.isPatch && tag.baseVersion == version)
        .toList();

    if (patchTags.isEmpty) return null;

    // Sort berdasarkan patch number (descending)
    patchTags.sort((a, b) {
      final aNum = int.tryParse(a.patchNumber) ?? 0;
      final bNum = int.tryParse(b.patchNumber) ?? 0;
      return bNum.compareTo(aNum);
    });

    final latestTag = patchTags.first;

    // Ambil release notes
    final releaseNotes = await getReleaseNotesForTag(
      owner: owner,
      repository: repository,
      tag: latestTag.name,
      token: token,
    );

    return PatchInfo(
      tagName: latestTag.name,
      version: version,
      patchVersion: latestTag.patchNumber,
      releaseNotes: releaseNotes ?? '',
      publishedAt: DateTime.now(), // GitHub API tag tidak memberikan published_at
    );
  }
}