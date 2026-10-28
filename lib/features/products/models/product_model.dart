class Product {
  const Product ({
    required this.id,
    required this.description,
    required this.price,
    required this.title,
    required this.category,
    required this.thumbnail,
    this.brand,
    this.images = const[],
    this.stock,
    this.rating,
    this.discountPercentage,


});

  final int id;
  final String description;
  final double price;
  final String title;
  final String category;
  final String thumbnail;
  final String? brand;
  final List<String> images;
  final int? stock;
  final double? rating;
  final double? discountPercentage;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return Product(
      id:(json['id'] as num?)?.toInt() ?? 0,
      title:json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      brand: json['brand'] as String?,
      images: rawImages is List
          ? rawImages.whereType<String>().toList()
          : const [],
      stock: (json['stock'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'thumbnail': thumbnail,
      'brand': brand,
      'images': images,
      'stock': stock,
      'rating': rating,
      'discountPercentage': discountPercentage,
    };
  }

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? thumbnail,
    String? brand,
    List<String>? images,
    int? stock,
    double? rating,
    double? discountPercentage,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      thumbnail: thumbnail ?? this.thumbnail,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }


}