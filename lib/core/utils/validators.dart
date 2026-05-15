import '../../app/localization.dart';

class Validators {
  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'تکایە ناونیشان بنووسە';
    if (text.length < 5) return 'ناونیشانەکە زۆر کورتە';
    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'تکایە وەسف بنووسە';
    if (text.length < 20) return 'وەسفەکە زۆر کورتە';
    return null;
  }

  static String? requiredSelection(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final regex = RegExp(r'^(?:\+964|00964|0)?7[3-9][0-9]{8}$');
    if (!regex.hasMatch(text.replaceAll(' ', ''))) {
      return 'ژمارەی تەلەفۆن دروست نییە';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(text)) return 'ئیمەیڵ دروست نییە';
    return null;
  }

  static String imageCount(int count) {
    if (count == 0) return 'تکایە لانیکەم یەک وێنە زیاد بکە';
    if (count > 5) return 'تەنها دەتوانیت ٥ وێنە زیاد بکەیت';
    return Ku.confirm;
  }
}
