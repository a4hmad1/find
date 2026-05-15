import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/kurdish_date_picker.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _area = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String? _postType;
  String? _itemType;
  String? _city;
  DateTime _eventDate = DateTime.now();
  bool _needsVerification = true;
  bool _allowPublicContact = false;
  bool _loading = false;
  List<XFile> _images = [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _area.dispose();
    _location.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showKurdishDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (result != null) setState(() => _eventDate = result);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final signedIn = ref.read(signedInProvider);
    if (!valid ||
        _postType == null ||
        _itemType == null ||
        _city == null ||
        (signedIn && _images.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            signedIn && _images.isEmpty
                ? 'تکایە لانیکەم یەک وێنە زیاد بکە'
                : Ku.requiredFields,
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final input = CreatePostInput(
        title: _title.text.trim(),
        description: _description.text.trim(),
        postType: _postType!,
        itemType: _itemType!,
        city: _city!,
        area: _area.text.trim(),
        locationText: _location.text.trim(),
        eventDate: _eventDate,
        contactPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        contactEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
        allowContactPublic: _allowPublicContact,
        needsVerification: _needsVerification,
      );
      final post = signedIn
          ? await ref.read(postsRepositoryProvider).createPost(input, _images)
          : await ref
                .read(localPostsProvider.notifier)
                .addGuestPost(input, _images);
      ref.invalidate(recentPostsProvider);
      ref.invalidate(postStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(Ku.postCreated)));
      context.go('${AppRoutes.post}/${post.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(Ku.genericError)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'زیادکردنی بابەتی نوێ',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OfficialHeader(
              title: 'زانیاری شتەکە بنووسە',
              subtitle:
                  'دەتوانیت بەبێ چوونەژوورەوە بابەتی نموونەیی زیاد بکەیت.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              validator: Validators.title,
              decoration: const InputDecoration(labelText: 'ناونیشانی بابەت'),
            ),
            const SizedBox(height: 12),
            Text(
              'جۆری بابەت',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            PostTypeSelector(
              value: _postType,
              onChanged: (value) => setState(() => _postType = value),
            ),
            const SizedBox(height: 12),
            ItemTypeDropdown(
              value: _itemType,
              onChanged: (value) => setState(() => _itemType = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 8,
              validator: Validators.description,
              decoration: const InputDecoration(labelText: 'وەسفکردن'),
            ),
            const SizedBox(height: 12),
            CityDropdown(
              value: _city,
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'ناوچە'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'شوێن'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('ڕێکەوتی دۆزینەوە / ونبوون / دزین'),
              subtitle: Text(DateFormatters.date(_eventDate)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('دیاریکردن'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              validator: Validators.phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'ژمارەی پەیوەندی',
                helperText: 'ئارەزوومەندانە',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ئیمەیڵ',
                helperText: 'ئارەزوومەندانە',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowPublicContact,
              onChanged: (value) => setState(() => _allowPublicContact = value),
              title: const Text('زانیاری پەیوەندی بە ئاشکرا نیشان بدرێت'),
              subtitle: const Text('تەنها ئەگەر خۆت ڕێگە بدەیت پیشان دەدرێت.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _needsVerification,
              onChanged: (value) => setState(() => _needsVerification = value),
              title: const Text('پێش پەیوەندیکردن پشتڕاستکردنەوە پێویستە'),
            ),
            const SizedBox(height: 18),
            Text(
              'وێنە زیاد بکە',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              'لە دۆخی میواندا ئەگەر وێنە زیاد نەکەیت، وێنەی نموونەیی دادەنرێت.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            ImagePickerGrid(
              images: _images,
              onChanged: (images) => setState(() => _images = images),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'بابەتەکە بنێرە',
              icon: Icons.send_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
