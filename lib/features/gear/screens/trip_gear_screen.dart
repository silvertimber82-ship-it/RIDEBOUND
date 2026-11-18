
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip_gear.dart';
import '../repositories/gear_repository.dart';
import '../../trips/models/trip.dart';

class TripGearScreen extends StatelessWidget {
  final Trip trip;

  const TripGearScreen({
    super.key,
    required this.trip,
  });


  Future<void> _addFromInventory(BuildContext context) async {
    final repository = context.read<GearRepository>();

    final selectedIds = <String>{};
    bool isAdding = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final masterItems = repository.gearItems;
            final tripItems = repository.getTripGear(trip.id);

            final addedIds = tripItems
                .map((item) => item.sourceGearItemId)
                .whereType<String>()
                .toSet();

            final availableItems = masterItems
                .where((item) => !addedIds.contains(item.id))
                .toList();

            final availableIds =
            availableItems.map((item) => item.id).toSet();

            final selectedCount =
                selectedIds.intersection(availableIds).length;

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.75,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add From My Gear',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isAdding
                                ? null
                                : () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    if (availableItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$selectedCount selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: isAdding
                                  ? null
                                  : () {
                                setSheetState(() {
                                  if (selectedCount ==
                                      availableItems.length) {
                                    selectedIds.clear();
                                  } else {
                                    selectedIds
                                      ..clear()
                                      ..addAll(availableIds);
                                  }
                                });
                              },
                              child: Text(
                                selectedCount == availableItems.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: availableItems.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'All your inventory items have '
                                'already been added to this trip.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: availableItems.length,
                        itemBuilder: (context, index) {
                          final gear = availableItems[index];

                          return CheckboxListTile(
                            value: selectedIds.contains(gear.id),
                            onChanged: isAdding
                                ? null
                                : (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selectedIds.add(gear.id);
                                } else {
                                  selectedIds.remove(gear.id);
                                }
                              });
                            },
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            title: Text(gear.name),
                            subtitle: Text(gear.category),
                          );
                        },
                      ),
                    ),

                    if (availableItems.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: selectedCount == 0 || isAdding
                                ? null
                                : () async {
                              setSheetState(() {
                                isAdding = true;
                              });

                              try {
                                final selectedItems = availableItems
                                    .where(
                                      (item) =>
                                      selectedIds.contains(item.id),
                                )
                                    .toList();

                                for (final gear in selectedItems) {
                                  await repository.addMasterItemToTrip(
                                    gear,
                                    trip.id,
                                  );
                                }

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  setSheetState(() {
                                    isAdding = false;
                                  });

                                  ScaffoldMessenger.of(sheetContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not add all gear: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: isAdding
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.add),
                            label: Text(
                              isAdding
                                  ? 'Adding Gear...'
                                  : 'Add Selected ($selectedCount)',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _addCustomItem(BuildContext context) async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _CustomGearDialog(
          nameController: nameController,
          notesController: notesController,
        );
      },
    );

    if (name == null || !context.mounted) return;

    final notes = notesController.text.trim();

    final repository = context.read<GearRepository>();
    final existingItems = repository.getTripGear(trip.id);

    final newItem = TripGearItem(
      id: GearRepository.generateId(),
      tripId: trip.id,
      name: name,
      category: 'Trip Specific',
      notes: notes,
      sortOrder: existingItems.length,
    );

    await repository.addTripGearItem(newItem);
  }

  Future<void> _showAddOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Add From My Gear Inventory'),
                subtitle: const Text('Copy an existing saved gear item'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addFromInventory(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create Trip-Specific Item'),
                subtitle: const Text('Add something just for this trip'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addCustomItem(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(
      BuildContext context,
      TripGearItem item,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Gear?'),
        content: Text('Remove "${item.name}" from this trip checklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<GearRepository>().deleteTripGearItem(item.id);
    }
  }

  Widget _buildCategorySection(
      BuildContext context,
      GearRepository repository,
      String category,
      List<TripGearItem> categoryItems,
      ) {
    final packedCount =
        categoryItems.where((item) => item.isPacked).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.category_outlined),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$packedCount of ${categoryItems.length} packed'),
        children: [
          for (final item in categoryItems)
            CheckboxListTile(
              value: item.isPacked,
              onChanged: (_) async {
                await repository.togglePacked(item.id);
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.name,
                style: TextStyle(
                  decoration: item.isPacked
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                [
                  if (item.weightGrams != null)
                    '${item.weightGrams} g '
                        '(${(item.weightGrams! / 453.59237).toStringAsFixed(2)} lb)',
                  if (item.packingLocation != null)
                    item.packingLocation!,
                ].join(' • '),
              ),
              secondary: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteItem(context, item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove from trip'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<GearRepository>();
    final items = repository.getTripGear(trip.id);

    final packedCount = repository.getPackedCount(trip.id);
    final totalCount = items.length;
    final progress = repository.getPackingProgress(trip.id);

    const categoryOrder = [
      'Riding Gear',
      'Motorcycle',
      'Camping Gear',
      'Personal Gear',
      'Trip Specific',
    ];

    final groupedItems = <String, List<TripGearItem>>{};

    for (final item in items) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    final sortedCategories = [
      ...categoryOrder.where((category) => groupedItems.containsKey(category)),
      ...groupedItems.keys.where(
            (category) => !categoryOrder.contains(category),
      ),
    ];


    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Gear Checklist'),
      ),
      body: items.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.backpack_outlined,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing packed yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add gear from your inventory or create '
                    'items just for this trip.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showAddOptions(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Gear'),
              ),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Packing Progress'),
                      Text('$packedCount of $totalCount packed'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  if (progress == 1) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text('Everything is packed!'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          for (final category in sortedCategories)
            _buildCategorySection(
              context,
              repository,
              category,
              groupedItems[category]!,
            ),

          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showAddOptions(context),
            icon: const Icon(Icons.add),
            label: const Text('Add More Gear'),
          ),
        ],
      ),
      floatingActionButton: items.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class _CustomGearDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController notesController;

  const _CustomGearDialog({
    required this.nameController,
    required this.notesController,
  });

  @override
  State<_CustomGearDialog> createState() => _CustomGearDialogState();
}

class _CustomGearDialogState extends State<_CustomGearDialog> {
  @override
  void dispose() {
    widget.nameController.dispose();
    widget.notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trip-Specific Gear'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'Example: Extra fuel bottle',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = widget.nameController.text.trim();

            if (name.isEmpty) return;

            FocusScope.of(context).unfocus();
            Navigator.pop(context, name);
          },
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}
