import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class DocumentCacheService {
  static const _cacheFolderName = 'legal_documents';
  static const _manifestFileName = 'manifest.json';

  Future<Directory> _cacheDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(baseDir.path, _cacheFolderName));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String _fileName(LegalDocument document) {
    final safeUpdatedAt = document.updatedAt.replaceAll(':', '-');
    return '${document.slug}_$safeUpdatedAt.pdf';
  }

  Future<File> _localFile(LegalDocument document) async {
    final cacheDir = await _cacheDirectory();
    return File(p.join(cacheDir.path, _fileName(document)));
  }

  Future<bool> isCached(LegalDocument document) async {
    final file = await _localFile(document);
    return file.existsSync() && await file.length() > 0;
  }

  Future<File> getOrDownload(
    LegalDocument document, {
    void Function(double progress)? onProgress,
  }) async {
    final localFile = await _localFile(document);
    if (await localFile.exists() && await localFile.length() > 0) {
      return localFile;
    }

    if (document.fileUrl.isEmpty) {
      throw DocumentCacheException('У документа нет файла для скачивания.');
    }

    final request = http.Request('GET', Uri.parse(document.fileUrl));
    final response = await request.send();
    if (response.statusCode >= 400) {
      throw DocumentCacheException(
        'Не удалось скачать документ (${response.statusCode}).',
      );
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
    }

    await localFile.writeAsBytes(bytes, flush: true);
    return localFile;
  }

  Future<void> saveManifest(List<LegalDocument> documents) async {
    final cacheDir = await _cacheDirectory();
    final manifestFile = File(p.join(cacheDir.path, _manifestFileName));
    final payload = documents.map((document) => document.toJson()).toList();
    await manifestFile.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<List<LegalDocument>> readCachedManifest() async {
    final cacheDir = await _cacheDirectory();
    final manifestFile = File(p.join(cacheDir.path, _manifestFileName));
    if (!await manifestFile.exists()) {
      return const [];
    }

    final raw = await manifestFile.readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => LegalDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class DocumentCacheException implements Exception {
  const DocumentCacheException(this.message);

  final String message;

  @override
  String toString() => message;
}
