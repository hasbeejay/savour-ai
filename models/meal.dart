import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbnail;
  final String? youtubeUrl;
  final List<Map<String, String>> ingredients;

  Meal({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbnail,
    this.youtubeUrl,
    required this.ingredients,
  });

  // Factory constructor for parsing API JSON (from TheMealDB)
  factory Meal.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> ingredients = [];

    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];

      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty &&
          measure != null &&
          measure.toString().trim().isNotEmpty) {
        ingredients.add({
          'ingredient': ingredient.toString().trim(),
          'measure': measure.toString().trim(),
        });
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      category: json['strCategory'] ?? '',
      area: json['strArea'] ?? '',
      instructions: json['strInstructions'] ?? '',
      thumbnail: json['strMealThumb'] ?? '',
      youtubeUrl: json['strYoutube']?.toString().trim().isNotEmpty == true
          ? json['strYoutube']
          : null,
      ingredients: ingredients,
    );
  }

  // NEW: Factory constructor for parsing Firestore data
  factory Meal.fromFirestore(Map<String, dynamic> data) {
    print('🧾 Parsing Firestore data for Meal.fromFirestore');
    print('   Data keys: ${data.keys.toList()}');
    print('   Thumbnail field exists: ${data.containsKey('thumbnail')}');
    print('   Thumbnail value: ${data['thumbnail']}');

    // Handle ingredients conversion from Firestore
    List<Map<String, String>> ingredients = [];

    if (data['ingredients'] != null && data['ingredients'] is List) {
      try {
        final List<dynamic> ingredientsList = data['ingredients'] as List;
        for (var item in ingredientsList) {
          if (item is Map<String, dynamic>) {
            ingredients.add({
              'ingredient': item['ingredient']?.toString() ?? '',
              'measure': item['measure']?.toString() ?? ''
            });
          } else if (item is Map) {
            // Handle dynamic map type
            final dynamicMap = Map<String, dynamic>.from(item);
            ingredients.add({
              'ingredient': dynamicMap['ingredient']?.toString() ?? '',
              'measure': dynamicMap['measure']?.toString() ?? ''
            });
          }
        }
      } catch (e) {
        print('❌ Error parsing ingredients from Firestore: $e');
        print('   Ingredients data: ${data['ingredients']}');
      }
    }

    return Meal(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      instructions: data['instructions']?.toString() ?? '',
      thumbnail: data['thumbnail']?.toString() ?? '', // CRITICAL FOR IMAGES
      youtubeUrl: data['youtubeUrl']?.toString(),
      ingredients: ingredients,
    );
  }

  // Method for converting to Firestore JSON
  Map<String, dynamic> toJson() {
    print('💾 Converting Meal to JSON for Firestore');
    print('   Meal: $name, Thumbnail: $thumbnail');

    return {
      'id': id,
      'name': name,
      'category': category,
      'area': area,
      'instructions': instructions,
      'thumbnail': thumbnail,  // MUST BE INCLUDED
      'youtubeUrl': youtubeUrl ?? '',
      'ingredients': ingredients.map((ing) => {
        'ingredient': ing['ingredient'] ?? '',
        'measure': ing['measure'] ?? ''
      }).toList(),
      'savedAt': FieldValue.serverTimestamp(),
    };
  }

  String? get youtubeVideoId {
    final uri = Uri.tryParse(youtubeUrl ?? "");
    if (uri == null) return null;
    if (uri.host.contains('youtube.com') && uri.queryParameters['v'] != null) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }
    return null;
  }
}