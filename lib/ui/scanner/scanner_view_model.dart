import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/item_repository.dart';

/// What the scanner screen shows under the camera / id field.
sealed class ScannerState {
  const ScannerState();
}

/// Waiting for a code.
final class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

/// A code was read and is being looked up.
final class ScannerLookingUp extends ScannerState {
  const ScannerLookingUp(this.code);

  final String code;
}

/// The code is not an item of this inventory.
final class ScannerNotFound extends ScannerState {
  const ScannerNotFound(this.code);

  final String code;
}

final class ScannerError extends ScannerState {
  const ScannerError(this.message);

  final String message;
}

/// Turns a scanned code (or a typed id) into an item id.
///
/// The camera arrives in lab 4 (`mobile_scanner`). It will call [lookUp]
/// exactly like the manual field does today.
class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel(this._items);

  factory ScannerViewModel.of(BuildContext context) =>
      ScannerViewModel(context.read<ItemRepository>());

  final ItemRepository _items;

  ScannerState _state = const ScannerIdle();
  ScannerState get state => _state;

  bool _disposed = false;

  /// Accepts a plain id (`dt-crimp-16`) or a link printed on a label
  /// (`elestock://items/dt-crimp-16`, `https://…/items/dt-crimp-16`).
  /// Returns `null` for an empty code.
  static String? parseCode(String raw) {
    final code = raw.trim();
    if (code.isEmpty) return null;
    final uri = Uri.tryParse(code);
    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      // elestock://items/<id> parses "items" as the host.
      if (uri.host == 'items' && segments.length == 1) return segments.first;
      final i = segments.indexOf('items');
      if (i != -1 && i + 1 < segments.length) return segments[i + 1];
      return null;
    }
    return code;
  }

  /// Looks the code up. Returns the item id when the item exists, so that
  /// the screen can open its details; otherwise `null` and the state says
  /// why.
  Future<String?> lookUp(String raw) async {
    final id = parseCode(raw);
    if (id == null) {
      _setState(ScannerNotFound(raw.trim()));
      return null;
    }
    _setState(ScannerLookingUp(id));
    try {
      final item = await _items.fetchItem(id);
      if (item == null) {
        _setState(ScannerNotFound(id));
        return null;
      }
      _setState(const ScannerIdle());
      return item.id;
    } catch (_) {
      _setState(const ScannerError('Could not look up this code. Try again.'));
      return null;
    }
  }

  void reset() => _setState(const ScannerIdle());

  void _setState(ScannerState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
