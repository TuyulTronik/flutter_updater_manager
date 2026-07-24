/// Helper untuk manipulasi versi
class VersionUtils {
  const VersionUtils();

  /// Normalisasi versi (hapus awalan 'v', 'V', dll.)
  static String normalize(String version) {
    var cleaned = version.trim();
    
    // Hapus awalan 'v' atau 'V'
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }
    
    // Hapus build number (+build) untuk komparasi
    if (cleaned.contains('+')) {
      cleaned = cleaned.substring(0, cleaned.indexOf('+'));
    }
    
    return cleaned.trim();
  }

  /// Bandingkan dua versi (SemVer)
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  static int compareVersions(String v1, String v2) {
    final n1 = normalize(v1);
    final n2 = normalize(v2);
    
    final parts1 = n1.split('.').map(int.parse).toList();
    final parts2 = n2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    
    if (parts1.length < parts2.length) return -1;
    if (parts1.length > parts2.length) return 1;
    
    return 0;
  }

  /// Cek apakah versi 1 lebih baru dari versi 2
  static bool isNewer(String v1, String v2) {
    return compareVersions(v1, v2) > 0;
  }

  /// Cek apakah versi 1 sama dengan versi 2
  static bool isEqual(String v1, String v2) {
    return compareVersions(v1, v2) == 0;
  }

  /// Extract major version
  static int getMajor(String version) {
    final normalized = normalize(version);
    final parts = normalized.split('.');
    return int.tryParse(parts[0]) ?? 0;
  }

  /// Extract minor version
  static int getMinor(String version) {
    final normalized = normalize(version);
    final parts = normalized.split('.');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  /// Extract patch version
  static int getPatch(String version) {
    final normalized = normalize(version);
    final parts = normalized.split('.');
    return parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  }

  /// Extract build number (jika ada)
  static int? getBuildNumber(String version) {
    final cleaned = version.trim();
    if (cleaned.contains('+')) {
      final build = cleaned.split('+')[1];
      return int.tryParse(build);
    }
    return null;
  }
}