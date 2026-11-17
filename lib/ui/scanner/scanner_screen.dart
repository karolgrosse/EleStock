import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../item_details/item_details_screen.dart';
import 'scanner_view_model.dart';

/// Scan a box label to open its item. Until the camera arrives (lab 4) the
/// preview is a placeholder and the id can be typed in.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: ScannerViewModel.of,
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan')),
        body: const ScannerBody(),
      ),
    );
  }
}

/// The scanner content without a Scaffold, so the app shell can use it as a
/// tab. Needs a [ScannerViewModel] above it.
class ScannerBody extends StatefulWidget {
  const ScannerBody({super.key});

  @override
  State<ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<ScannerBody> {
  // Local UI state only: what is typed in the field.
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final vm = context.read<ScannerViewModel>();
    final navigator = Navigator.of(context);

    final id = await vm.lookUp(_code.text);
    if (id == null || !mounted) return;

    _code.clear();
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => ItemDetailsScreen(itemId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<ScannerViewModel>().state;
    final busy = state is ScannerLookingUp;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Where the camera preview goes in lab 4.
        Semantics(
          label: 'Camera preview, not available yet',
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera scanning arrives in lab 4',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('item-id-field'),
          controller: _code,
          enabled: !busy,
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            labelText: 'Or type the item id',
            hintText: 'e.g. dt-crimp-16',
            border: const OutlineInputBorder(),
            errorText: switch (state) {
              ScannerNotFound(:final code) when code.isEmpty =>
                'Enter an item id',
              ScannerNotFound(:final code) => 'No item with the id "$code"',
              ScannerError(:final message) => message,
              _ => null,
            },
          ),
          onChanged: (_) {
            if (state is ScannerNotFound || state is ScannerError) {
              context.read<ScannerViewModel>().reset();
            }
          },
          onSubmitted: (_) => _open(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _open,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.open_in_new),
          label: const Text('Open item'),
        ),
      ],
    );
  }
}
