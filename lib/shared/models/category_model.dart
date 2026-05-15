class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nameKu,
    required this.icon,
    required this.isActive,
  });

  final String id;
  final String nameKu;
  final String icon;
  final bool isActive;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      nameKu: json['name_ku']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category',
      isActive: json['is_active'] != false,
    );
  }
}
