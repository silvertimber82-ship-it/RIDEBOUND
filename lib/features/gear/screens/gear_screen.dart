
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gear_item.dart';
import '../repositories/gear_repository.dart';

class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  static const List<String> _defaultCategories = [
    GearItem.categoryRiding,
    GearItem.categoryMotorcycle,
    GearItem.categoryCamping,
    GearItem.categoryPersonal,
  ];

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<GearRepository>();
    final items = repository.gearItems;

    final categories = [
      ..._defaultCategories,
      ...items
          .map((item) => item.category)
          .where((category) => !_defaultCategories.contains(category))
          .toSet(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gear Inventory'),
        actions: [
          IconButton(
            tooltip: 'Add gear',
            onPressed: () => _showGearDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _InventorySummary(count: items.length),
          Expanded(
            child: items.isEmpty
                ? _EmptyGearState(
              onAdd: () => _showGearDialog(context),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final category in categories)
                  if (items.any(
                        (item) => item.category == category,
                  ))
                    _GearCategorySection(
                      category: category,
                      items: items
                          .where(
                            (item) => item.category == category,
                      )
                          .toList(),
                      onEdit: (item) => _showGearDialog(
                        context,
                        item: item,
                      ),
                      onDelete: (item) =>
                          _confirmDelete(context, item),
                    ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGearDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Gear'),
      ),
    );
  }

  Future<void> _showGearDialog(
      BuildContext context, {
        GearItem? item,
      }) async {
    final nameController = TextEditingController(
      text: item?.name ?? '',
    );

    final weightController = TextEditingController(
      text: item?.weightGrams?.toString() ?? '',
    );

    final notesController = TextEditingController(
      text: item?.notes ?? '',
    );

    final customCategoryController = TextEditingController();

    String category = item?.category ?? GearItem.categoryRiding;
    String? packingLocation = item?.defaultPackingLocation;
    String weightUnit = 'g';

    final repository = context.read<GearRepository>();

    final knownCategories = {
      ..._defaultCategories,
      ...repository.gearItems.map((gear) => gear.category),
    }.toList();

    final locations = [
      GearItem.locationSaddlebags,
      GearItem.locationTourPack,
      GearItem.locationBackpack,
      GearItem.locationTankBag,
      GearItem.locationWorn,
      GearItem.locationOther,
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(item == null ? 'Add Gear' : 'Edit Gear'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Item name',
                        hintText: 'Example: Sleeping bag',
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: knownCategories.contains(category)
                          ? category
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: knownCategories.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: customCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'New custom category (optional)',
                        hintText: 'Example: Electronics',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weight entry
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: weightController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: weightUnit == 'g'
                                ? 'Weight (grams)'
                                : 'Weight (pounds)',
                            hintText: weightUnit == 'g'
                                ? 'Example: 1200'
                                : 'Example: 2.5',
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: weightUnit,
                          decoration: const InputDecoration(
                            labelText: 'Weight unit',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'g',
                              child: Text('Grams'),
                            ),
                            DropdownMenuItem(
                              value: 'lb',
                              child: Text('Pounds'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null || value == weightUnit) {
                              return;
                            }

                            final currentWeight = double.tryParse(
                              weightController.text.trim(),
                            );

                            if (currentWeight != null) {
                              final convertedWeight = weightUnit == 'g'
                                  ? currentWeight / 453.59237
                                  : currentWeight * 453.59237;

                              weightController.text =
                                  convertedWeight.toStringAsFixed(2);
                            }

                            setDialogState(() {
                              weightUnit = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: packingLocation ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Default packing location',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Not specified'),
                        ),
                        ...locations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          packingLocation =
                          value == null || value.isEmpty ? null : value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Details about this item',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),

                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    final customCategory =
                    customCategoryController.text.trim();

                    final selectedCategory = customCategory.isNotEmpty
                        ? customCategory
                        : category;

                    final weightText = weightController.text.trim();

                    final enteredWeight = weightText.isEmpty
                        ? null
                        : double.tryParse(weightText);

                    if (weightText.isNotEmpty &&
                        (enteredWeight == null || enteredWeight < 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid weight greater than or equal to zero.',
                          ),
                        ),
                      );
                      return;
                    }

                    final int? weight = enteredWeight == null
                        ? null
                        : weightUnit == 'lb'
                        ? (enteredWeight * 453.59237).round()
                        : enteredWeight.round();

                    final updatedItem = GearItem(
                      id: item?.id ?? GearRepository.generateId(),
                      name: name,
                      category: selectedCategory,
                      weightGrams: weight,
                      defaultPackingLocation: packingLocation,
                      notes: notesController.text.trim(),
                      createdAt: item?.createdAt ?? DateTime.now(),
                    );

                    if (item == null) {
                      await repository.addGearItem(updatedItem);
                    } else {
                      await repository.updateGearItem(updatedItem);
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(
                    item == null ? 'Add Item' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Do not dispose these controllers here.
    // The dialog and keyboard focus notifications must finish first.
  }

  Future<void> _confirmDelete(
      BuildContext context,
      GearItem item,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Gear?'),
        content: Text('Remove "${item.name}" from your inventory?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<GearRepository>().deleteGearItem(item.id);
    }
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.backpack_outlined),
        ),
        title: const Text('My Gear'),
        subtitle: Text('$count items in your inventory'),
        trailing: Text(
          '$count',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _EmptyGearState extends StatelessWidget {
  const _EmptyGearState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.backpack_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Your gear inventory is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start adding your riding, motorcycle, '
                  'camping, and personal gear.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GearCategorySection extends StatelessWidget {
  const _GearCategorySection({
    required this.category,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final List<GearItem> items;
  final ValueChanged<GearItem> onEdit;
  final ValueChanged<GearItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.folder_outlined),
        title: Text(category),
        trailing: Text('${items.length}'),
        children: [
          for (final item in items)
            ListTile(
              leading: const Icon(Icons.backpack_outlined),
              title: Text(item.name),
              subtitle: Text(
                [
                  if (item.weightGrams != null)
                    '${item.weightGrams} g '
                        '(${(item.weightGrams! / 453.59237).toStringAsFixed(2)} lb)',
                  if (item.defaultPackingLocation != null)
                    item.defaultPackingLocation!,
                ].join(' • ').isEmpty
                    ? 'No additional details'
                    : [
                  if (item.weightGrams != null)
                    '${item.weightGrams} g '
                        '(${(item.weightGrams! / 453.59237).toStringAsFixed(2)} lb)',
                  if (item.defaultPackingLocation != null)
                    item.defaultPackingLocation!,
                ].join(' • '),
              ),
              onTap: () => onEdit(item),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(item);
                  }
                  if (value == 'delete') {
                    onDelete(item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
