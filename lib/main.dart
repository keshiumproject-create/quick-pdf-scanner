import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const QuickScannerApp());
}

class QuickScannerApp extends StatelessWidget {
  const QuickScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick PDF Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<File> _pdfFiles = [];
  bool _isProcessing = false;

  Future<void> _scanDocument({required int pageLimit}) async {
    setState(() => _isProcessing = true);
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: pageLimit,
        isGalleryImport: true,
      );

      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();
      await scanner.close();

      if (result.images.isNotEmpty) {
        final pdf = pw.Document();
        for (final imagePath in result.images) {
          final imageBytes = await File(imagePath).readAsBytes();
          final pdfImage = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) => pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            ),
          );
        }

        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'Belge_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(await pdf.save());

        setState(() {
          _pdfFiles.insert(0, file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hızlı PDF & Kimlik Tarayıcı')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _pdfFiles.isEmpty
              ? const Center(
                  child: Text('Henüz belge taranmadı.\nAlttaki butonlardan taramaya başla.',
                      textAlign: TextAlign.center),
                )
              : ListView.builder(
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pdfFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      title: Text(file.path.split('/').last),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => Share.shareXFiles([XFile(file.path)]),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _scanDocument(pageLimit: 10),
                icon: const Icon(Icons.document_scanner),
                label: const Text('Belge Tara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _scanDocument(pageLimit: 2),
                icon: const Icon(Icons.badge),
                label: const Text('Kimlik (2 Yüz)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
