import 'package:flutter/material.dart';

/// セクションカードウィジェット
/// 
/// 見出し付きのカードセクションを表示
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  
  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}