import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 20, 0, 0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xff070000),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}