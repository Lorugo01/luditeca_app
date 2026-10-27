/// Mapeamento URL remota → ficheiro local durante a leitura de um livro.
class BookOfflineSession {
  BookOfflineSession._();

  static int? activeBookId;
  static final Map<String, String> _urlToLocal = {};

  static void activate(int bookId, Map<String, String> urlToLocalPath) {
    activeBookId = bookId;
    _urlToLocal
      ..clear()
      ..addAll(urlToLocalPath);
  }

  /// Regista um ficheiro descarregado em segundo plano (só se o livro
  /// ainda estiver aberto).
  static void register(int bookId, String remoteUrl, String localPath) {
    if (activeBookId != bookId) return;
    _urlToLocal[remoteUrl.trim()] = localPath;
  }

  static void clear() {
    activeBookId = null;
    _urlToLocal.clear();
  }

  /// Devolve caminho local ou a URL original se não houver cache.
  static String resolve(String? remoteUrl) {
    if (remoteUrl == null) return '';
    final trimmed = remoteUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    return _urlToLocal[trimmed] ?? trimmed;
  }

  static bool isLocalPath(String path) {
    if (path.isEmpty) return false;
    return path.startsWith('/') ||
        (path.length > 2 && path[1] == ':') ||
        path.startsWith('file://');
  }
}
