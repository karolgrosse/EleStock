import 'package:flutter/material.dart';

import 'ui/inventory/inventory_screen.dart';

void main() => runApp(const EleStockApp());

class EleStockApp extends StatelessWidget {
  const EleStockApp({super.key});

  static const _seed = Color.fromARGB(255, 251, 159, 201);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EleStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const InventoryScreen(),
    );
  }
}
