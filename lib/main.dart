import 'package:flutter/material.dart';
import 'package:ree/features/reader/screens/import.dart';
import 'package:ree/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await openHiveBoxes();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ree',
      themeMode: ThemeMode.light,
      home: const ImportPage(),
    );
  }
}
