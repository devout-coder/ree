import 'package:ree/features/reader/screens/reader.dart';
import 'package:routemaster/routemaster.dart';
import 'package:flutter/material.dart';

final routeMap = RouteMap(routes: {
  "/": (_) => const MaterialPage(child: BookView()),
});
