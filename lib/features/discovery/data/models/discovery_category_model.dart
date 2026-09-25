import 'package:equatable/equatable.dart';

/// Model cho thể loại board game trong discovery filter.
class DiscoveryCategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  const DiscoveryCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
  });

  factory DiscoveryCategoryModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? json['name'].toString().toLowerCase().replaceAll(' ', '-'),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [id, name, slug, sortOrder];
}
