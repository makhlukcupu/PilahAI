import 'package:flutter/material.dart';

class WasteDetailScreen extends StatelessWidget {
  final String label;

  WasteDetailScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
      ),
      body: Center(
        child: Text("Details about $label", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}