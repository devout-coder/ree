import 'package:flutter/material.dart';

double paddingHorizontal = 16;
double paddingVertical = 16;

final Map<String, TextStyle> tagStyles = {
  // Headings
  'h1': const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
  ),
  'h2': const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
  ),
  'h3': const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
  'h4': const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
  'h5': const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
  'h6': const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),

  // Block elements
  'p': const TextStyle(
    fontSize: 16,
    height: 1.5,
  ),
  'blockquote': TextStyle(
    fontSize: 16,
    height: 1.5,
    fontStyle: FontStyle.italic,
    color: Colors.grey[700],
  ),
  'pre': const TextStyle(
    fontSize: 14,
    height: 1.4,
    fontFamily: 'monospace',
  ),

  // Inline elements
  'strong': const TextStyle(
    fontWeight: FontWeight.bold,
  ),
  'b': const TextStyle(
    fontWeight: FontWeight.bold,
  ),
  'em': const TextStyle(
    fontStyle: FontStyle.italic,
  ),
  'i': const TextStyle(
    fontStyle: FontStyle.italic,
  ),
  'u': const TextStyle(
    decoration: TextDecoration.underline,
  ),
  'strike': const TextStyle(
    decoration: TextDecoration.lineThrough,
  ),
  'code': TextStyle(
    fontFamily: 'monospace',
    backgroundColor: Colors.grey[200],
  ),
  'small': const TextStyle(
    fontSize: 12,
  ),
  'sub': const TextStyle(
    fontSize: 12,
    textBaseline: TextBaseline.alphabetic,
  ),
  'sup': const TextStyle(
    fontSize: 12,
    textBaseline: TextBaseline.alphabetic,
  ),

  // List elements
  'li': const TextStyle(
    fontSize: 16,
    height: 1.5,
  ),

  // Table elements
  'th': const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
  'td': const TextStyle(
    fontSize: 16,
  ),

  // Links
  'a': const TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  ),
};
