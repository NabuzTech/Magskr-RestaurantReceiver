import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fromDate;
  final String toDate;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String? _tempPath;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _saveTempFile();
  }

  Future<void> _saveTempFile() async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/report_${widget.fromDate}_${widget.toDate}.pdf');
    await file.writeAsBytes(widget.pdfBytes);
    setState(() => _tempPath = file.path);
  }

  Future<void> _downloadPdf() async {
    try {
      final fileName =
          'Sales_Report_${widget.fromDate}_${widget.toDate}.pdf';
      String fullPath;

      if (Platform.isAndroid) {
        fullPath = await _saveOnAndroid(fileName);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        fullPath = '${dir.path}/$fileName';
        await File(fullPath).writeAsBytes(widget.pdfBytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'pdf_saved'.tr}:\n$fullPath',
              maxLines: 3,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'download_error'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String> _saveOnAndroid(String fileName) async {
    // Try public Downloads folder first
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final fullPath = '${downloadDir.path}/$fileName';
        await File(fullPath).writeAsBytes(widget.pdfBytes);
        return fullPath;
      }
    } catch (_) {}

    // Fallback: app-specific external storage
    try {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        final fullPath = '${dirs.first.path}/$fileName';
        await File(fullPath).writeAsBytes(widget.pdfBytes);
        return fullPath;
      }
    } catch (_) {}

    // Last fallback: internal documents
    final dir = await getApplicationDocumentsDirectory();
    final fullPath = '${dir.path}/$fileName';
    await File(fullPath).writeAsBytes(widget.pdfBytes);
    return fullPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'report_preview'.tr,
          style: const TextStyle(
            fontFamily: "Mulish",
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _tempPath == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                Expanded(
                  child: PDFView(
                    filePath: _tempPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                        _isReady = true;
                      });
                    },
                    onViewCreated: (controller) {},
                    onPageChanged: (page, total) {
                      setState(() {
                        _currentPage = page ?? 0;
                      });
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${'error'.tr}: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                if (_isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        '${'page_indicator'.tr} ${_currentPage + 1} ${'of'.tr} $_totalPages',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: "Mulish",
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _downloadPdf,
                      icon:
                          const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'download_pdf'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: "Mulish",
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
