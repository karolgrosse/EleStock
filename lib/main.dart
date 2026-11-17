import 'package:flutter/material.dart';

import 'ui/inventory/inventory_screen.dart';

void main() => runApp(const EleStockApp());

class EleStockApp extends StatelessWidget {
  const EleStockApp({super.key});

  static const _seed = Color.fromARGB(255, 251, 159, 201);
  static const minWidth = 320.0; // Any smaller and the app shits itself - MW

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EleStock',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= minWidth) return child!;
          final media = MediaQuery.of(context);
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: minWidth,
              maxWidth: minWidth,
              child: MediaQuery(
                data: media.copyWith(size: Size(minWidth, media.size.height)),
                child: child!,
              ),
            ),
          );
        },
      ),
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
