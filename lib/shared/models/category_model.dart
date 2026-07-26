import '../../core/utils/json.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nameKu,
    required this.icon,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json.asString('id'),
      nameKu: json.asString('name_ku'),
      icon: json.asString('icon', ifAbsent: 'category'),
      isActive: json.asBool('is_active', ifAbsent: true),
    );
  }

  final String id;
  final String nameKu;
  final String icon;
  final bool isActive;
}
