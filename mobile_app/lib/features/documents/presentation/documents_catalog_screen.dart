import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';
import '../../../core/storage/document_cache_service.dart';
import 'document_viewer_screen.dart';

class DocumentsCatalogScreen extends StatelessWidget {
  const DocumentsCatalogScreen({
    super.key,
    required this.documents,
    required this.cacheService,
  });

  final List<LegalDocument> documents;
  final DocumentCacheService cacheService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Полезные документы'),
      ),
      body: documents.isEmpty
          ? const Center(
              child: Text(
                'Документы пока не загружены на сервер.\nДобавьте PDF в Django admin.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = documents[index];
                return _DocumentTile(
                  document: document,
                  cacheService: cacheService,
                );
              },
            ),
    );
  }
}

class _DocumentTile extends StatefulWidget {
  const _DocumentTile({
    required this.document,
    required this.cacheService,
  });

  final LegalDocument document;
  final DocumentCacheService cacheService;

  @override
  State<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<_DocumentTile> {
  bool _isCached = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _refreshCachedState();
  }

  Future<void> _refreshCachedState() async {
    final cached = await widget.cacheService.isCached(widget.document);
    if (mounted) {
      setState(() => _isCached = cached);
    }
  }

  Future<void> _openDocument() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          document: widget.document,
          cacheService: widget.cacheService,
        ),
      ),
    );
    await _refreshCachedState();
  }

  Future<void> _downloadForOffline() async {
    setState(() => _isDownloading = true);
    try {
      await widget.cacheService.getOrDownload(widget.document);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Документ сохранён для офлайн-доступа')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
        await _refreshCachedState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(
          widget.document.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          widget.document.description.isEmpty
              ? 'PDF • ${_formatSize(widget.document.fileSize)}'
              : widget.document.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: Icon(
          _isCached ? Icons.offline_pin_rounded : Icons.description_outlined,
          color: _isCached ? const Color(0xFF2E83FF) : Colors.white70,
        ),
        trailing: _isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'open') {
                    _openDocument();
                  } else if (value == 'offline') {
                    _downloadForOffline();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('Открыть')),
                  const PopupMenuItem(
                    value: 'offline',
                    child: Text('Сохранить для офлайн'),
                  ),
                ],
              ),
        onTap: _openDocument,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) {
      return 'размер неизвестен';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(0)} КБ';
    }
    return '${(kb / 1024).toStringAsFixed(1)} МБ';
  }
}
