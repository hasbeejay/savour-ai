import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:savourai/models/meal.dart';
import 'package:savourai/screens/chat.dart';
import 'package:savourai/screens/mealpage.dart';
import 'package:savourai/screens/search.dart';
import 'package:savourai/screens/account.dart';
import 'package:savourai/services/favourites_service.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  Meal? recipeOfTheDay;
  List<Meal> randomRecipes = [];
  bool isLoading = true;
  bool _loadingMore = false;
  bool _hasMoreRecipes = true;
  int _currentPage = 0;
  final int _recipesPerPage = 10;
  final FavoritesService _favoritesService = FavoritesService();
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userName; // Store user's name
  final ScrollController _scrollController = ScrollController();
  int _lastSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
    _fetchUserName(); // Fetch user's name

    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _loadInitialRecipes() async {
    setState(() => isLoading = true);

    try {
      // Load Recipe of the Day
      final randomMeal = await fetchRandomMeal();
      if (randomMeal != null) {
        recipeOfTheDay = randomMeal;
      }

      // Load initial batch of recipes
      await _loadMoreRecipes();
    } catch (e) {
      print('Error loading recipes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (!_hasMoreRecipes || _loadingMore) return;

    setState(() => _loadingMore = true);

    try {
      final newRecipes = await fetchMultipleMeals(_recipesPerPage);

      setState(() {
        randomRecipes.addAll(newRecipes);
        _currentPage++;
        _loadingMore = false;

        // If we got fewer recipes than requested, we've reached the end
        if (newRecipes.length < _recipesPerPage) {
          _hasMoreRecipes = false;
        }
      });
    } catch (e) {
      print('Error loading more recipes: $e');
      setState(() => _loadingMore = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      // Load more recipes when user reaches the bottom
      if (_hasMoreRecipes && !_loadingMore) {
        _loadMoreRecipes();
      }
    }
  }

  Future<List<Meal>> fetchMultipleMeals(int count) async {
    List<Meal> meals = [];
    Set<String> existingIds = randomRecipes.map((meal) => meal.id).toSet();

    for (int i = 0; i < count; i++) {
      try {
        final meal = await fetchRandomMeal();
        if (meal != null && !existingIds.contains(meal.id)) {
          meals.add(meal);
          existingIds.add(meal.id);
        }
      } catch (e) {
        print('Error fetching meal $i: $e');
      }

      // Small delay to avoid rate limiting
      if (i < count - 1) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return meals;
  }

  Future<Meal?> fetchRandomMeal() async {
    const url = 'https://www.themealdb.com/api/json/v1/1/random.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mealsList = data['meals'] as List<dynamic>;
        if (mealsList.isNotEmpty) {
          return Meal.fromJson(mealsList.first);
        }
      }
    } catch (e) {
      print('Error fetching meal: $e');
    }
    return null;
  }

  void _refreshRecipes() {
    setState(() {
      randomRecipes.clear();
      _currentPage = 0;
      _hasMoreRecipes = true;
      isLoading = true;
    });

    _loadInitialRecipes();
  }

  // NEW: Create a Future function for RefreshIndicator
  Future<void> _refreshHomeContent() async {
    _refreshRecipes();
  }

  // NEW: Handle navigation bar tap
  void _onNavigationBarTap(int index) {
    if (index == 0 && index == _lastSelectedIndex) {
      // User tapped home icon while already on home page
      _refreshRecipes();
      // Scroll to top
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      selectedIndex = index;
      _lastSelectedIndex = index;
    });
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 186, 107, 60),
              Color.fromARGB(255, 234, 134, 76),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.restaurant,
                    color: Color.fromARGB(255, 237, 135, 75),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // UPDATED: Use user's actual name
                        "Welcome back, ${_userName?.split(' ').first ?? 'Chef'}! 👨‍🍳",
                        style: GoogleFonts.ptSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Ready to cook something amazing today?",
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeOfTheDayCard() {
    if (recipeOfTheDay == null) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 150,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealPage(
              meal: recipeOfTheDay!,
              backgroundColor: Colors.amber,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                recipeOfTheDay!.thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "RECIPE OF THE DAY",
                            style: GoogleFonts.ptSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipeOfTheDay!.name,
                      style: GoogleFonts.ptSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "● ${recipeOfTheDay!.category} ● ${recipeOfTheDay!.area}",
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Chat()),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 9, 55, 115),
                const Color.fromARGB(255, 15, 101, 214),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 30,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ask ChefBot AI",
                      style: GoogleFonts.ptSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Get cooking tips, recipe ideas, and meal planning help",
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomRecipeCard(Meal meal, int index) {
    // Track favorite state for each card
    bool isFavorited = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // Check favorite status when card builds
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final status = await _favoritesService.isMealFavorited(meal.id);
          if (mounted && status != isFavorited) {
            setState(() {
              isFavorited = status;
            });
          }
        });

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
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.only(bottom: 15),
            child: Container(
              height: 120,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    child: Image.network(
                      meal.thumbnail,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            meal.name,
                            style: GoogleFonts.ptSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "● ${meal.category} ● ${meal.area}",
                            style: GoogleFonts.ptSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 14,
                                color: Colors.orange[800],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${meal.ingredients.length} ingredients",
                                style: GoogleFonts.ptSans(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (isFavorited) {
                              await _favoritesService.removeFromFavorites(meal.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed from favorites'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              await _favoritesService.addToFavorites(meal);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to favorites! ❤️'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            // Update UI immediately
                            setState(() {
                              isFavorited = !isFavorited;
                            });
                          },
                          icon: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHomeContent, // Use the Future function
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10), // Added space for status bar
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildRecipeOfTheDayCard(),
            const SizedBox(height: 20),
            _buildAIChatCard(),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Discover Recipes",
                  style: GoogleFonts.ptSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _refreshRecipes, // This works because it's void
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 18),
                      const SizedBox(width: 5),
                      Text("Refresh All"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Show all recipes with infinite scrolling
            ...randomRecipes.asMap().entries.map((entry) {
              return _buildRandomRecipeCard(entry.value, entry.key);
            }).toList(),

            // Loading indicator for infinite scroll
            if (_loadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // End of list message
            if (!_hasMoreRecipes && randomRecipes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "You've reached the end!",
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [Scaffold(body: _buildHomeContent()), Search(), Chat(), AccountScreen()];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, // Added to handle status bar
      body: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 245, 240),
        ),
        child: SafeArea( // Wrapped with SafeArea to avoid status bar overlap
          bottom: false, // Keep bottom navigation bar overlapping
          child: pages[selectedIndex],
        ),
      ),
      bottomNavigationBar: CrystalNavigationBar(
        borderRadius: 15,
        currentIndex: selectedIndex,
        unselectedItemColor: const Color.fromARGB(215, 255, 255, 255),
        backgroundColor: Colors.black.withOpacity(0.1),
        outlineBorderColor: Colors.white,
        onTap: _onNavigationBarTap, // Updated to use new handler
        items: [
          CrystalNavigationBarItem(
            icon: IconlyBold.home,
            unselectedIcon: IconlyLight.home,
            selectedColor: Colors.brown,
          ),
          CrystalNavigationBarItem(
            icon: IconlyBold.search,
            unselectedIcon: IconlyLight.search,
            selectedColor: Colors.orange,
          ),
          CrystalNavigationBarItem(
            icon: IconlyBold.chat,
            unselectedIcon: IconlyLight.chat,
            selectedColor: Colors.orange,
          ),
          CrystalNavigationBarItem(
            icon: IconlyBold.profile,
            unselectedIcon: IconlyLight.profile,
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}