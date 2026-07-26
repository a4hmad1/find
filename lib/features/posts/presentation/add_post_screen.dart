import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/domain/post_type.dart';
import '../../../core/errors/app_failure.dart';
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

  PostType? _postType;
  String? _itemType;
  String? _city;
  DateTime _eventDate = DateTime.now();
  bool _needsVerification = true;
  bool _allowPublicContact = false;
  bool _submitting = false;
  List<XFile> _images = const [];

  /// Set when a required selection is missing, so the error appears next to the
  /// control rather than only in a snack bar the user has to remember.
  bool _showSelectionErrors = false;

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
    if (result == null || !mounted) return;
    setState(() => _eventDate = result);
  }

  Future<void> _submit() async {
    final signedIn = ref.read(signedInProvider);
    final formValid = _formKey.currentState?.validate() ?? false;
    final selectionsValid =
        _postType != null && _itemType != null && _city != null;
    // Guests may post without a photo — a stock image stands in. Signed-in
    // posts are public records, so at least one real photo is required.
    final imagesValid = !signedIn || _images.isNotEmpty;

    if (!formValid || !selectionsValid || !imagesValid) {
      setState(() => _showSelectionErrors = true);
      showMessageSnackBar(
        context,
        !imagesValid ? Ku.addImage : Ku.requiredFields,
      );
      return;
    }

    setState(() => _submitting = true);
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
        contactPhone: _phone.text.trim().nullIfEmpty,
        contactEmail: _email.text.trim().nullIfEmpty,
        allowContactPublic: _allowPublicContact,
        needsVerification: _needsVerification,
      );

      final post = signedIn
          ? await ref.read(postsRepositoryProvider).createPost(input, _images)
          : await ref
                .read(localPostsProvider.notifier)
                .addGuestPost(input, _images);

      ref
        ..invalidate(recentPostsProvider)
        ..invalidate(urgentPostsProvider)
        ..invalidate(postStatsProvider)
        ..invalidate(myPostsProvider);

      if (!mounted) return;
      showMessageSnackBar(context, Ku.postCreated);
      context.go('${AppRoutes.post}/${post.id}');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      // Report the actual reason — a daily-quota rejection and a dropped
      // connection previously produced the same opaque message.
      showFailureSnackBar(context, failure, onRetry: _submit);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);

    return AppScaffold(
      title: 'زیادکردنی بابەتی نوێ',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfficialHeader(
              title: 'زانیاری شتەکە بنووسە',
              subtitle: signedIn
                  ? 'بابەتەکەت پاش پشتڕاستکردنەوەی بەڕێوەبەر بڵاو دەبێتەوە.'
                  : 'دەتوانیت بەبێ چوونەژوورەوە بابەتی نموونەیی زیاد بکەیت.',
            ),
            const SizedBox(height: 18),
            if (!signedIn) ...[
              const InfoBanner(
                message:
                    'لە دۆخی میواندا بابەتەکە تەنها لەسەر ئەم ئامێرە دەمێنێتەوە و بڵاو ناکرێتەوە.',
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _title,
              validator: Validators.title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'ناونیشانی بابەت'),
            ),
            const SizedBox(height: 16),
            _FieldLabel(
              label: 'جۆری بابەت',
              error: _showSelectionErrors && _postType == null
                  ? 'تکایە جۆری بابەت دیاری بکە'
                  : null,
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
            if (_showSelectionErrors && _itemType == null)
              const _FieldError('تکایە جۆری شت دیاری بکە'),
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
            if (_showSelectionErrors && _city == null)
              const _FieldError('تکایە شار دیاری بکە'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _area,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'ناوچە'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textInputAction: TextInputAction.next,
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
              signedIn
                  ? 'لانیکەم یەک وێنە پێویستە، زۆرترین ${AppLimits.maxPostImages} وێنە.'
                  : 'لە دۆخی میواندا ئەگەر وێنە زیاد نەکەیت، وێنەی نموونەیی دادەنرێت.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            ImagePickerGrid(
              images: _images,
              enabled: !_submitting,
              onChanged: (images) => setState(() => _images = images),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'بابەتەکە بنێرە',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.error});

  final String label;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (error case final message?) _FieldError(message),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

extension on String {
  /// Treats a blank optional field as absent rather than storing an empty
  /// string, so `allow_contact_public` never advertises an empty phone number.
  String? get nullIfEmpty => isEmpty ? null : this;
}
