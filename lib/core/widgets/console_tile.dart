import 'package:flutter/material.dart';

class ConsoleTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final Widget trailing;

  const ConsoleTile({required this.name, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(name), subtitle: Text(subtitle), trailing: trailing);
  }
}
