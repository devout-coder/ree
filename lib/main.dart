import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import "./router.dart";

void main() async {
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Ree',
      themeMode: ThemeMode.light,
      routerDelegate: RoutemasterDelegate(routesBuilder: (context) {
        return routeMap;
      }),
      routeInformationParser: const RoutemasterParser(),
    );
  }
}
