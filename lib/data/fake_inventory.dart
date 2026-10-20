import '../domain/models/item.dart';
import '../domain/models/stock_transaction.dart';

// Fake data for lab 1. Replaced by drift + Supabase in lab 3.

const fakeItems = <Item>[
  Item(
    id: 'dt-crimp-16',
    name: 'Deutsch DT crimp contacts, size 16, nickel',
    category: ItemCategory.connectors,
    location: 'Shelf A / Box 1',
    quantity: 6,
    unit: 'pcs',
    lowStockThreshold: 20,
    partNumber: '0462-201-16141',
  ),
  Item(
    id: 'dt-04-housing',
    name: 'Deutsch DT04-4P receptacle',
    category: ItemCategory.connectors,
    location: 'Shelf A / Box 2',
    quantity: 14,
    unit: 'pcs',
    lowStockThreshold: 5,
    partNumber: 'DT04-4P',
  ),
  Item(
    id: 'm6-bolt',
    name: 'M6×20 bolt, 12.9, black oxide',
    category: ItemCategory.fasteners,
    location: 'Shelf C / Drawer 4',
    quantity: 120,
    unit: 'pcs',
    lowStockThreshold: 40,
  ),
  Item(
    id: 'm5-nyloc',
    name: 'M5 nyloc nut',
    category: ItemCategory.fasteners,
    location: 'Shelf C / Drawer 5',
    quantity: 0,
    unit: 'pcs',
    lowStockThreshold: 30,
  ),
  Item(
    id: 'bms-slave',
    name:
        'Accumulator BMS slave PCB rev. C (spare, tested, '
        'with conformal coating and pre-soldered balancing harness)',
    category: ItemCategory.electronics,
    location: 'ESD cabinet / Tray 2',
    quantity: 3,
    unit: 'pcs',
    lowStockThreshold: 2,
    notes: 'Handle on the ESD mat only.',
  ),
  Item(
    id: 'tps',
    name: 'Throttle position sensor',
    category: ItemCategory.sensors,
    location: 'Shelf B / Box 3',
    quantity: 2,
    unit: 'pcs',
    lowStockThreshold: 2,
  ),
  Item(
    id: 'crimp-tool',
    name: 'Deutsch HDT-48-00 crimp tool',
    category: ItemCategory.tools,
    location: 'Tool wall',
    quantity: 1,
    unit: 'pcs',
    lowStockThreshold: 0,
  ),
  Item(
    id: 'heatshrink',
    name: 'Heat shrink 3:1, 6 mm, black',
    category: ItemCategory.consumables,
    location: 'Shelf A / Box 6',
    quantity: 8,
    unit: 'm',
    lowStockThreshold: 5,
  ),
];

// Deliberately not in date order: the screen sorts them with newestFirst().
final fakeTransactions = <StockTransaction>[
  StockTransaction(
    id: 't1',
    itemId: 'dt-crimp-16',
    memberName: 'Ola Nowak',
    type: TransactionType.take,
    quantity: 4,
    timestamp: DateTime(2026, 10, 19, 18, 30),
    note: 'Steering wheel harness',
  ),
  StockTransaction(
    id: 't2',
    itemId: 'm6-bolt',
    memberName: 'Jan Kowalski',
    type: TransactionType.restock,
    quantity: 100,
    timestamp: DateTime(2026, 10, 12, 10),
  ),
  StockTransaction(
    id: 't3',
    itemId: 'm5-nyloc',
    memberName: 'Jan Kowalski',
    type: TransactionType.take,
    quantity: 24,
    timestamp: DateTime(2026, 10, 18, 21, 5),
    note: 'Rear wing mounts',
  ),
  StockTransaction(
    id: 't4',
    itemId: 'tps',
    memberName: 'Marie Dubois-Lefèvre (Erasmus, powertrain)',
    type: TransactionType.putBack,
    quantity: 1,
    timestamp: DateTime(2026, 10, 20, 9, 15),
  ),
  StockTransaction(
    id: 't5',
    itemId: 'heatshrink',
    memberName: 'Ola Nowak',
    type: TransactionType.adjust,
    quantity: -2,
    timestamp: DateTime(2026, 10, 15, 17),
    note: 'Stock count before the event',
  ),
  StockTransaction(
    id: 't6',
    itemId: 'dt-crimp-16',
    memberName: 'Jan Kowalski',
    type: TransactionType.take,
    quantity: 10,
    timestamp: DateTime(2026, 10, 16, 14, 40),
  ),
];

Item? fakeItemById(String id) {
  for (final item in fakeItems) {
    if (item.id == id) return item;
  }
  return null;
}
