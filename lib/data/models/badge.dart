class Badge {
  const Badge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.criteria,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? criteria;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'criteria': criteria,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? 'Badge',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      criteria: json['criteria'] as String?,
    );
  }
}
