import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/domain/post_type.dart';

/// The app's search field.
class KurdishSearchBar extends StatelessWidget {
  const KurdishSearchBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onFilter,
    this.hasActiveFilters = false,
    this.hint = 'چی لەدەستت داوە یان چی دۆزیوتەوە؟',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilter;

  /// Tints the filter icon so an active filter is visible without opening the
  /// sheet — otherwise an empty result set looks like a broken search.
  final bool hasActiveFilters;

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onFilter == null
            ? null
            : IconButton(
                tooltip: Ku.filter,
                onPressed: onFilter,
                isSelected: hasActiveFilters,
                icon: Icon(
                  hasActiveFilters
                      ? Icons.filter_alt_rounded
                      : Icons.tune_rounded,
                  color: hasActiveFilters ? AppColors.primary : null,
                ),
              ),
      ),
    );
  }
}

/// Dropdown over a fixed list of options, with an optional "all" entry.
///
/// Replaces the four near-identical dropdowns that each re-implemented the
/// empty-string-means-null convention.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.allowAll = false,
    this.allLabel = 'هەموو',
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onChanged;
  final bool allowAll;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowAll) DropdownMenuItem<T?>(child: Text(allLabel)),
        for (final item in items)
          DropdownMenuItem<T?>(value: item, child: Text(labelOf(item))),
      ],
      onChanged: onChanged,
    );
  }
}

class CityDropdown extends StatelessWidget {
  const CityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAll = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    return LabeledDropdown<String>(
      label: 'شار',
      value: value,
      items: AppLists.cities,
      labelOf: (city) => city,
      allowAll: allowAll,
      onChanged: onChanged,
    );
  }
}

class ItemTypeDropdown extends StatelessWidget {
  const ItemTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAll = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    return LabeledDropdown<String>(
      label: 'جۆری شت',
      value: value,
      items: AppLists.itemTypes,
      labelOf: (type) => type,
      allowAll: allowAll,
      onChanged: onChanged,
    );
  }
}

/// Choice chips for picking whether an item was found, lost, or stolen.
class PostTypeSelector extends StatelessWidget {
  const PostTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PostType? value;
  final ValueChanged<PostType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in PostType.values)
          ChoiceChip(
            label: Text(type.label),
            selected: value == type,
            onSelected: (_) => onChanged(type),
          ),
      ],
    );
  }
}

/// Grid of picked images with an add tile.
///
/// Decodes each thumbnail once into a cached [Uint8List] rather than kicking off
/// a fresh `readAsBytes` future on every rebuild, which previously made the grid
/// flicker whenever the parent form rebuilt.
class ImagePickerGrid extends StatefulWidget {
  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = AppLimits.maxPostImages,
    this.enabled = true,
  });

  final List<XFile> images;
  final ValueChanged<List<XFile>> onChanged;
  final int maxImages;
  final bool enabled;

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  final _thumbnails = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    unawaitedDecode(widget.images);
  }

  @override
  void didUpdateWidget(ImagePickerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.images, widget.images)) {
      unawaitedDecode(widget.images);
    }
  }

  /// Reads any images we have not decoded yet, dropping cache entries for files
  /// the user removed.
  void unawaitedDecode(List<XFile> images) {
    final paths = images.map((file) => file.path).toSet();
    _thumbnails.removeWhere((path, _) => !paths.contains(path));

    for (final file in images) {
      if (_thumbnails.containsKey(file.path)) continue;
      file.readAsBytes().then((bytes) {
        if (!mounted) return;
        setState(() => _thumbnails[file.path] = bytes);
      });
    }
  }

  Future<void> _pick() async {
    final remaining = widget.maxImages - widget.images.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
      limit: remaining,
    );
    if (picked.isEmpty) return;

    widget.onChanged(
      [...widget.images, ...picked].take(widget.maxImages).toList(),
    );
  }

  void _remove(int index) {
    widget.onChanged([...widget.images]..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = widget.enabled && widget.images.length < widget.maxImages;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.images.length + (canAdd ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index == widget.images.length) return _AddTile(onTap: _pick);
        return _Thumbnail(
          bytes: _thumbnails[widget.images[index].path],
          onRemove: widget.enabled ? () => _remove(index) : null,
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD7E3F1)),
        ),
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.bytes, required this.onRemove});

  final Uint8List? bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes case final data?)
            Image.memory(data, fit: BoxFit.cover, gaplessPlayback: true)
          else
            const ColoredBox(color: AppColors.primarySoft),
          if (onRemove case final remove?)
            PositionedDirectional(
              top: 6,
              start: 6,
              child: Material(
                color: AppColors.danger,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: remove,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
