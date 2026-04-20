import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:savourai/models/meal.dart';
import 'package:savourai/screens/mealpage.dart';
import 'package:savourai/services/favourites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FavoritesService _favoritesService = FavoritesService();
  List<Meal> savedMeals = [];
  List<Meal> favoriteMeals = [];
  bool isLoading = true;
  String _appVersion = "";
  bool _showAbout = false;
  String? _userName; // Store user's name

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppInfo();
    _fetchUserName(); // Fetch user's name
  }

  // NEW: Fetch user's name from Firestore
  Future<void> _fetchUserName() async {
    if (user == null) {
      setState(() => _userName = null);
      return;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'];
        });
      } else {
        // Fallback to Firebase Auth display name
        setState(() {
          _userName = user?.displayName;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        _userName = user?.displayName; // Fallback
      });
    }
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = "${info.version}+${info.buildNumber}";
    });
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Load saved meals
      final savedStream = _favoritesService.getSavedMealsStream();
      savedStream.listen((meals) {
        print("📥 Saved meals updated: ${meals.length} items");
        for (var meal in meals) {
          print("   - ${meal.name} (Thumbnail: ${meal.thumbnail})");
        }
        setState(() {
          savedMeals = meals;
        });
      });

      // Load favorite meals
      final favStream = _favoritesService.getFavoriteMealsStream();
      favStream.listen((meals) {
        print("❤️  Favorite meals updated: ${meals.length} items");
        for (var meal in meals) {
          print("   - ${meal.name} (Thumbnail: ${meal.thumbnail})");
        }
        setState(() {
          favoriteMeals = meals;
          isLoading = false;
        });
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  // NEW: Function to update user name
  Future<void> _updateUserName() async {
    if (user == null) return;

    final TextEditingController nameController = TextEditingController(
      text: _userName ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF753C03),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _userName) {
      setState(() => isLoading = true);
      try {
        // Update in Firestore
        await _firestore
            .collection('users')
            .doc(user!.uid)
            .update({'name': newName});

        // Update in Firebase Auth (optional)
        await user!.updateDisplayName(newName);

        setState(() {
          _userName = newName;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Name updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        });
      } catch (e) {
        print('Error updating name: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  // Function to remove from saved
  Future<void> _removeFromSaved(String mealId) async {
    try {
      await _favoritesService.removeFromSaved(mealId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from saved'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error removing from saved: $e');
    }
  }

  // Function to remove from favorites
  Future<void> _removeFromFavorites(String mealId) async {
    try {
      await _favoritesService.removeFromFavorites(mealId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  void _launchURL(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 245, 240),
      extendBody: true, // Added this to make navigation bar overlap
      body: SafeArea(
        bottom: false, // Changed from default to false for overlapping bottom nav bar
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 129, 74, 41),
                      const Color.fromARGB(255, 129, 74, 41),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF753C03),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // UPDATED: Display actual user name with edit option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName ?? 'Savour User',
                          style: GoogleFonts.ptSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _updateUserName,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.ptSans(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Saved',
                          savedMeals.length.toString(),
                          Icons.bookmark,
                        ),
                        _buildStatCard(
                          'Favorites',
                          favoriteMeals.length.toString(),
                          Icons.favorite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // About Section Toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.blue[700]),
                    title: Text(
                      'About Savour',
                      style: GoogleFonts.ptSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      _showAbout ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () {
                      setState(() {
                        _showAbout = !_showAbout;
                      });
                    },
                  ),
                ),
              ),

              // About Content
              if (_showAbout) _buildAboutSection(),

              // Saved Recipes Section
              _buildSectionTitle('Saved Recipes', Icons.bookmark, savedMeals),
              isLoading
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
                  : savedMeals.isEmpty
                  ? _buildEmptyState('No saved recipes yet')
                  : _buildMealGrid(savedMeals, isSaved: true),

              // Favorites Section
              _buildSectionTitle('Favorite Recipes', Icons.favorite, favoriteMeals),
              isLoading
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
                  : favoriteMeals.isEmpty
                  ? _buildEmptyState('No favorites yet')
                  : _buildMealGrid(favoriteMeals, isSaved: false),

              // Account Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                                'Are you sure you want to delete your account? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // Delete from Firestore first
                                  await _firestore
                                      .collection('users')
                                      .doc(user!.uid)
                                      .delete();
                                  // Then delete from Auth
                                  await user!.delete();
                                  await _signOut();
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              // Reduced bottom padding to account for overlapping nav bar
              const SizedBox(height: 30), // Reduced from 50 to 30
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange[800], size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.ptSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/transparentApplogo.png",
                height: 120,
              ),
              const SizedBox(height: 10),
              Text(
                "Version: $_appVersion",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 20, color: Colors.black),
              Text(
                "Savour is more than just a recipe app—it’s your intelligent cooking companion, built from the ground up with Flutter to deliver a seamless cross-platform experience. Born from a Mobile Computing semester project, Savour addresses a universal kitchen dilemma: the frustration of getting lost in a recipe, juggling between text and a separate video, or wishing for instant help when a step goes unclear.\n\nThe Problem We Solved: Cooking should be joyful, not confusing. Traditional apps leave users switching tabs, scrubbing through long videos, or frantically searching for clarification mid-chop. We identified a need for an integrated, guided cooking experience that reduces stress and boosts confidence in the kitchen.\n\nOur AI-Powered Solution: Savour elegantly combines three key features to create a cohesive cooking journey:\n\nComplete, Curated Recipes: Discover a wide range of dishes with clear, structured ingredient lists and step-by-step instructions.\n\nIntegrated Video Tutorials: Watch precise, step-along videos directly within each recipe, so you can see the technique exactly when you need it.\n\nThis project was developed as part of a Mobile Computing semester course, showcasing the practical application of Flutter, Dart, and integrated AI APIs to solve a real-world user experience challenge.",
                style: GoogleFonts.ptSans(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "App Created By",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "hasbeejay and raheemxghumman",
                style: GoogleFonts.ptSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _launchURL(
                        " "),
                    icon: Image.asset("assets/github.png", height: 40),
                  ),
                  IconButton(
                    onPressed: () => _launchURL(
                        " "),
                    icon: Image.asset("assets/linkedin.png", height: 40),
                  ),
                  IconButton(
                    onPressed: () => _launchURL(
                        " "),
                    icon: Image.asset("assets/instapng.png", height: 35),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Added meals parameter to show count
  Widget _buildSectionTitle(String title, IconData icon, List<Meal> meals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange[800]),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.ptSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '(${meals.length})',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_food_beverage, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // UPDATED: Added remove functionality and better image handling
  Widget _buildMealGrid(List<Meal> meals, {required bool isSaved}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MealPage(
                    meal: meal,
                    backgroundColor: Colors.amber,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: meal.thumbnail,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "● ${meal.category ?? ''}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (isSaved) {
                        _removeFromSaved(meal.id);
                      } else {
                        _removeFromFavorites(meal.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_remove : Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}