import 'package:flutter/material.dart';

import '../../domain/models/item.dart';

extension ItemCategoryUi on ItemCategory {
  String get label => switch (this) {
    ItemCategory.connectors => 'Connectors',
    ItemCategory.electronics => 'Electronics',
    ItemCategory.fasteners => 'Fasteners',
    ItemCategory.sensors => 'Sensors',
    ItemCategory.tools => 'Tools',
    ItemCategory.consumables => 'Consumables',
  };

  IconData get icon => switch (this) {
    ItemCategory.connectors => Icons.cable,
    ItemCategory.electronics => Icons.memory,
    ItemCategory.fasteners => Icons.hardware,
    ItemCategory.sensors => Icons.sensors,
    ItemCategory.tools => Icons.handyman,
    ItemCategory.consumables => Icons.inventory_2,
  };
}
