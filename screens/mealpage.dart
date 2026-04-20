import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:savourai/models/meal.dart';
import 'package:savourai/services/favourites_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MealPage extends StatefulWidget {
  final Meal meal;
  final Color backgroundColor;
  const MealPage({Key? key, required this.meal, required this.backgroundColor})
      : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  bool isFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final favorite = await _favoritesService.isMealFavorited(widget.meal.id);
    setState(() {
      isFavorite = favorite;
    });
  }

  Future<void> _toggleFavorite() async {
    try {
      if (isFavorite) {
        await _favoritesService.removeFromFavorites(widget.meal.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _favoritesService.addToFavorites(widget.meal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to favorites!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Update the UI state
      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 25, 15, 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: widget.backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: meal.thumbnail,
                        height: screenHeight * 0.4,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Icon(Icons.broken_image, size: 50);
                        },
                      ),
                      Container(
                        alignment: Alignment.bottomLeft,
                        height: screenHeight * 0.4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromARGB(0, 0, 0, 0),
                              Color.fromARGB(170, 0, 0, 0),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                overflow: TextOverflow.fade,
                                meal.name,
                                style: GoogleFonts.ptSansNarrow(
                                  color: Colors.white,
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().fade(duration: Duration(seconds: 1)),
                              Text(
                                "● ${meal.category ?? ''} ● ${meal.area ?? ''}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Save to saved recipes
                                _favoritesService.saveMeal(meal);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Recipe saved!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.bookmark_add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "I N G R E D I E N T S",
                      style: GoogleFonts.ptSans(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: meal.ingredients.map((item) {
                        final ingredient = item['ingredient'] ?? '';
                        final measure = item['measure'] ?? '';
                        return Text(
                          '• $ingredient - $measure',
                          style: GoogleFonts.ptSans(),
                        ).animate().fade();
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "H O W   T O   C O O K ?",
                      style: GoogleFonts.ptSans(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      meal.instructions,
                      style: GoogleFonts.ptSans(),
                    ).animate().fade(),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "V I D E O \t T U T O R I A L",
                      style: GoogleFonts.ptSans(fontSize: 20),
                    ),
                  ),
                  if (meal.youtubeVideoId != null)
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(
                            'https://www.youtube.com/watch?v=${meal.youtubeVideoId}',
                          );
                          if (!await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'This recipe was not added to Youtube yet.',
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl:
                                'https://img.youtube.com/vi/${meal.youtubeVideoId}/0.jpg',
                                height: 200,
                                width: MediaQuery.of(context).size.width * 0.85,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, err) {
                                  return Image.asset(
                                    "assets/ytError.png",
                                    height: 200,
                                    width:
                                    MediaQuery.of(context).size.width * 0.85,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 64,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}