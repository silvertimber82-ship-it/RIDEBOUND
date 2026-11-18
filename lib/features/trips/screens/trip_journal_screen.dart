import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry.dart';
import '../models/trip.dart';
import '../repositories/trip_repository.dart';

class TripJournalScreen extends StatefulWidget {
  final Trip trip;

  const TripJournalScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripJournalScreen> createState() => _TripJournalScreenState();
}

class _TripJournalScreenState extends State<TripJournalScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  Future<void> _addJournalEntry() async {
    final entry = await showDialog<JournalEntry>(
      context: context,
      builder: (dialogContext) => const _JournalEntryDialog(),
    );

    if (entry == null || !mounted) return;

    final updatedTrip = _trip.copyWith(
      journalEntries: [..._trip.journalEntries, entry],
    );

    await context.read<TripRepository>().updateTrip(updatedTrip);
    if (!mounted) return;

    setState(() => _trip = updatedTrip);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry saved')),
    );
  }

  Future<void> _editJournalEntry(JournalEntry originalEntry) async {
    final updatedEntry = await showDialog<JournalEntry>(
      context: context,
      builder: (dialogContext) =>
          _JournalEntryDialog(entry: originalEntry),
    );

    if (updatedEntry == null || !mounted) return;

    final updatedEntries = _trip.journalEntries.map((entry) {
      return entry.id == originalEntry.id ? updatedEntry : entry;
    }).toList();

    final updatedTrip = _trip.copyWith(journalEntries: updatedEntries);

    await context.read<TripRepository>().updateTrip(updatedTrip);
    if (!mounted) return;

    setState(() => _trip = updatedTrip);

    await _deleteRemovedJournalPhotos(
      originalEntry.photoPaths,
      updatedEntry.photoPaths,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry updated')),
    );
  }
  Future<void> _deleteJournalEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Journal Entry?'),
          content: const Text(
            'This will permanently delete this entry and its photos. '
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final updatedEntries = _trip.journalEntries
        .where((item) => item.id != entry.id)
        .toList();

    final updatedTrip = _trip.copyWith(
      journalEntries: updatedEntries,
    );

    try {
      await context.read<TripRepository>().updateTrip(updatedTrip);

      if (!mounted) return;

      setState(() {
        _trip = updatedTrip;
      });

      try {
        await _deleteRemovedJournalPhotos(
          entry.photoPaths,
          const [],
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Entry deleted, but some photo files could not be removed.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete journal entry: $e'),
        ),
      );
    }
  }
  Future<void> _deleteRemovedJournalPhotos(
      List<String> oldPaths,
      List<String> retainedPaths,
      ) async {
    final retained = retainedPaths.toSet();
    final appDirectory = await getApplicationDocumentsDirectory();
    final journalDirectory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}journal_photos',
    ).absolute.path;

    for (final path in oldPaths) {
      if (retained.contains(path)) continue;

      final file = File(path).absolute;
      if (file.parent.path == journalDirectory && await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Journal')),
      body: SafeArea(
        child: _trip.journalEntries.isEmpty
            ? const Center(child: Text('No journal entries yet.'))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _trip.journalEntries.length,
          itemBuilder: (context, index) {
            final entry = _trip.journalEntries[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit entry',
                          onPressed: () => _editJournalEntry(entry),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete entry',
                          onPressed: () => _deleteJournalEntry(entry),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(entry.content),
                    if (entry.photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry.photoPaths.length,
                          separatorBuilder: (context, photoIndex) =>
                          const SizedBox(width: 8),
                          itemBuilder: (context, photoIndex) {
                            final photoPath = entry.photoPaths[photoIndex];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        _JournalPhotoViewer(
                                          photoPaths: entry.photoPaths,
                                          initialIndex: photoIndex,
                                        ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(photoPath),
                                  width: 120,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 110,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 32,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addJournalEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}
class _JournalEntryDialog extends StatefulWidget {
  final JournalEntry? entry;

  const _JournalEntryDialog({
    this.entry,
  });

  @override
  State<_JournalEntryDialog> createState() =>
      _JournalEntryDialogState();
}

class _JournalEntryDialogState extends State<_JournalEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedImages = [];
  late List<String> _existingPhotoPaths;

  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.entry?.title ?? '',
    );

    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );

    _existingPhotoPaths = List<String>.from(
      widget.entry?.photoPaths ?? [],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted || images.isEmpty) return;

      setState(() {
        _selectedImages.addAll(images);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select photos: $e'),
        ),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingPhotoPaths.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    try {
      final appDirectory =
      await getApplicationDocumentsDirectory();

      final photoDirectory = Directory(
        '${appDirectory.path}/journal_photos',
      );

      if (!await photoDirectory.exists()) {
        await photoDirectory.create(recursive: true);
      }

      final savedPhotoPaths = List<String>.from(
        _existingPhotoPaths,
      );

      final timestamp = DateTime.now().microsecondsSinceEpoch;

      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        final extension = image.path.contains('.')
            ? image.path.split('.').last
            : 'jpg';

        final fileName = 'journal_${timestamp}_$i.$extension';

        final destination = File(
          '${photoDirectory.path}/$fileName',
        );

        await File(image.path).copy(destination.path);

        savedPhotoPaths.add(destination.path);
      }

      final originalEntry = widget.entry;

      final entry = JournalEntry(
        id: originalEntry?.id ?? timestamp.toString(),
        title: title,
        content: content,
        createdAt: originalEntry?.createdAt ?? DateTime.now(),
        photoPaths: savedPhotoPaths,
      );

      if (!mounted) return;

      FocusScope.of(context).unfocus();
      Navigator.pop(context, entry);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save journal entry: $e'),
        ),
      );
    }
  }

  Widget _buildPhotoPreview(
      String path,
      VoidCallback onRemove,
      ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 90,
                height: 90,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: _isSaving ? null : onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Entry Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an entry title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'What happened on this ride?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Journal Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Photos'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (_existingPhotoPaths.isEmpty &&
                    _selectedImages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No photos selected.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...List.generate(
                        _existingPhotoPaths.length,
                            (index) {
                          final path = _existingPhotoPaths[index];

                          return _buildPhotoPreview(
                            path,
                                () => _removeExistingImage(index),
                          );
                        },
                      ),
                      ...List.generate(
                        _selectedImages.length,
                            (index) {
                          final path = _selectedImages[index].path;

                          return _buildPhotoPreview(
                            path,
                                () => _removeNewImage(index),
                          );
                        },
                      ),
                    ],
                  ),

                if (_existingPhotoPaths.isNotEmpty ||
                    _selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_existingPhotoPaths.length + _selectedImages.length} photo(s)',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveEntry,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : Text(_isEditing ? 'Save Changes' : 'Save Entry'),
        ),
      ],
    );
  }
}

class _JournalPhotoViewer extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;

  const _JournalPhotoViewer({
    required this.photoPaths,
    required this.initialIndex,
  });

  @override
  State<_JournalPhotoViewer> createState() =>
      _JournalPhotoViewerState();
}

class _JournalPhotoViewerState extends State<_JournalPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} of ${widget.photoPaths.length}',
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoPaths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(
                File(widget.photoPaths[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}