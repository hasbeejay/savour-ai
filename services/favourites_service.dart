import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savourai/models/meal.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> saveMeal(Meal meal) async {
    if (_user == null) {
      print('❌ Cannot save meal: User not logged in');
      return;
    }

    try {
      print('💾 Saving meal to Firestore: ${meal.name} (ID: ${meal.id})');
      print('   Thumbnail URL: ${meal.thumbnail}');

      await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('saved')
          .doc(meal.id)
          .set(meal.toJson(), SetOptions(merge: true));

      print('✅ Meal saved successfully!');
    } catch (e) {
      print('❌ Error saving meal: $e');
      rethrow;
    }
  }

  Future<void> addToFavorites(Meal meal) async {
    if (_user == null) {
      print('❌ Cannot add favorite: User not logged in');
      return;
    }

    try {
      print('❤️ Adding to favorites: ${meal.name} (ID: ${meal.id})');

      await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('favorites')
          .doc(meal.id)
          .set(meal.toJson(), SetOptions(merge: true));

      print('✅ Added to favorites successfully!');
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromSaved(String mealId) async {
    if (_user == null) {
      print('❌ Cannot remove saved: User not logged in');
      return;
    }

    try {
      print('🗑️ Removing from saved: $mealId');

      await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('saved')
          .doc(mealId)
          .delete();

      print('✅ Removed from saved successfully!');
    } catch (e) {
      print('❌ Error removing from saved: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String mealId) async {
    if (_user == null) {
      print('❌ Cannot remove favorite: User not logged in');
      return;
    }

    try {
      print('💔 Removing from favorites: $mealId');

      await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('favorites')
          .doc(mealId)
          .delete();

      print('✅ Removed from favorites successfully!');
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<bool> isMealSaved(String mealId) async {
    if (_user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('saved')
          .doc(mealId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if meal saved: $e');
      return false;
    }
  }

  Future<bool> isMealFavorited(String mealId) async {
    if (_user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('favorites')
          .doc(mealId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if meal favorited: $e');
      return false;
    }
  }

  Stream<List<Meal>> getSavedMealsStream() {
    if (_user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('saved')
        .snapshots()
        .handleError((error) {
      print('❌ Stream error for saved meals: $error');
    })
        .map((snapshot) {
      print('📥 Saved meals stream update: ${snapshot.docs.length} items');

      final meals = snapshot.docs.map((doc) {
        final data = doc.data();
        print('   📄 Document data for ${doc.id}:');
        print('   🖼️ Thumbnail in data: ${data['thumbnail']}');

        try {
          // CORRECTED: Use the factory constructor directly
          return Meal.fromFirestore(data);
        } catch (e) {
          print('❌ Error parsing meal from Firestore: $e');
          print('   Data: $data');
          // Create a placeholder meal if parsing fails
          return Meal(
            id: data['id']?.toString() ?? doc.id,
            name: data['name']?.toString() ?? 'Unknown Recipe',
            category: data['category']?.toString() ?? '',
            area: data['area']?.toString() ?? '',
            instructions: data['instructions']?.toString() ?? '',
            thumbnail: data['thumbnail']?.toString() ?? 'https://via.placeholder.com/150',
            ingredients: _parseIngredients(data['ingredients']),
          );
        }
      }).toList();

      return meals;
    });
  }

  Stream<List<Meal>> getFavoriteMealsStream() {
    if (_user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('favorites')
        .snapshots()
        .handleError((error) {
      print('❌ Stream error for favorite meals: $error');
    })
        .map((snapshot) {
      print('📥 Favorite meals stream update: ${snapshot.docs.length} items');

      final meals = snapshot.docs.map((doc) {
        final data = doc.data();
        print('   📄 Document data for ${doc.id}:');
        print('   🖼️ Thumbnail in data: ${data['thumbnail']}');

        try {
          // CORRECTED: Use the factory constructor directly
          return Meal.fromFirestore(data);
        } catch (e) {
          print('❌ Error parsing meal from Firestore: $e');
          print('   Data: $data');
          // Create a placeholder meal if parsing fails
          return Meal(
            id: data['id']?.toString() ?? doc.id,
            name: data['name']?.toString() ?? 'Unknown Recipe',
            category: data['category']?.toString() ?? '',
            area: data['area']?.toString() ?? '',
            instructions: data['instructions']?.toString() ?? '',
            thumbnail: data['thumbnail']?.toString() ?? 'https://via.placeholder.com/150',
            ingredients: _parseIngredients(data['ingredients']),
          );
        }
      }).toList();

      return meals;
    });
  }

  // Helper method to parse ingredients safely
  List<Map<String, String>> _parseIngredients(dynamic ingredientsData) {
    if (ingredientsData == null) return [];

    try {
      if (ingredientsData is List) {
        return ingredientsData.map((item) {
          if (item is Map<String, dynamic>) {
            return {
              'ingredient': item['ingredient']?.toString() ?? '',
              'measure': item['measure']?.toString() ?? ''
            };
          }
          return {'ingredient': '', 'measure': ''};
        }).toList();
      }
    } catch (e) {
      print('❌ Error parsing ingredients: $e');
    }

    return [];
  }

  // Helper method to clear all saved/favorites (for testing)
  Future<void> clearAllData() async {
    if (_user == null) return;

    try {
      // Delete all saved meals
      final savedSnapshot = await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('saved')
          .get();

      for (var doc in savedSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all favorites
      final favSnapshot = await _firestore
          .collection('users')
          .doc(_user.uid)
          .collection('favorites')
          .get();

      for (var doc in favSnapshot.docs) {
        await doc.reference.delete();
      }

      print('🧹 Cleared all saved and favorite data');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}