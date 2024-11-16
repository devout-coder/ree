import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ree/features/reader/screens/reader.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  FilePickerResult? result;
  void pickFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Books',
      extensions: <String>['epub', 'pdf'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

    if (file != null) {
      Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookView(
            bookBytes: bytes,
          ),
        ),
      );
    } else {
      // User canceled the picker
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                pickFile();
              },
              child: const Text("Pick File"),
            )
          ],
        ),
      )),
    );
  }
}
