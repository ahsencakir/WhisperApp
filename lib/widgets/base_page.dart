import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'custom_drawer.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget body;

  const BasePage({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title),
      drawer: const CustomDrawer(),
      body: body,
    );
  }
} 