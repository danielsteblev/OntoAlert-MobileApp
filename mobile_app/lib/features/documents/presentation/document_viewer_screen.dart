import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/models/app_models.dart';
import '../../../core/storage/document_cache_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({
    super.key,
    required this.document,
    required this.cacheService,
  });

  final LegalDocument document;
  final DocumentCacheService cacheService;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PdfControllerPinch? _pdfController;
  double _progress = 0;
  String? _error;
  bool _isOfflineFile = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _error = null;
      _progress = 0;
    });

    try {
      final alreadyCached = await widget.cacheService.isCached(widget.document);
      final file = await widget.cacheService.getOrDownload(
        widget.document,
        onProgress: (value) {
          if (mounted) {
            setState(() => _progress = value);
          }
        },
      );
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(file.path),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isOfflineFile = alreadyCached;
      });
    } on DocumentCacheException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Не удалось открыть документ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF282828),
        title: Text(
          widget.document.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_isOfflineFile)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.offline_pin_rounded, color: Color(0xFF2E83FF)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadDocument, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    if (_pdfController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _progress > 0
                  ? 'Скачивание ${(_progress * 100).toStringAsFixed(0)}%'
                  : 'Подготовка документа...',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_progress > 0 && _progress < 1)
          LinearProgressIndicator(value: _progress),
        Expanded(
          child: PdfViewPinch(controller: _pdfController!),
        ),
      ],
    );
  }
}
