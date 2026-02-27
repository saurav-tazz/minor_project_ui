import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GenreScreen extends StatefulWidget {
  const GenreScreen({super.key});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  // 🔹 Preserved: 'id' mapping for backend vector logic
  final List<Map<String, dynamic>> genres = [
    {'id': 0, 'title': 'Society & Culture', 'icon': Icons.public},
    {'id': 1, 'title': 'Science & Mathematics', 'icon': Icons.science},
    {'id': 2, 'title': 'Health', 'icon': Icons.health_and_safety},
    {'id': 3, 'title': 'Education & Reference', 'icon': Icons.menu_book},
    {'id': 4, 'title': 'Computers & Internet', 'icon': Icons.computer},
    {'id': 5, 'title': 'Sports', 'icon': Icons.sports_esports},
    {'id': 6, 'title': 'Business & Finance', 'icon': Icons.payments},
    {'id': 7, 'title': 'Entertainment & Music', 'icon': Icons.music_note},
    {'id': 8, 'title': 'Family & Relationships', 'icon': Icons.people},
    {'id': 9, 'title': 'Politics & Government', 'icon': Icons.gavel},
  ];

  final List<int> selectedIndexes = [];
  bool isLoading = false;

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    });
  }

  // 🔹 UPDATED: Logic to sync with Cosine Similarity Backend
  Future<void> savePreferences() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final selectedGenreIds = selectedIndexes
          .map((i) => genres[i]['id'])
          .toList();

      final response = await http.post(
        Uri.parse(
          'https://quiz-royale-ash0.onrender.com/api/users/update-genres',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'preferredGenres': selectedGenreIds, // Matches backend key
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        // Passes the updated user object (with level/points) to HomeScreen
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: data['user'],
        );
      } else {
        throw Exception('Failed to save preferences');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            const Text(
              'Choose Your Genre',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select at least one genre to help us find the perfect opponent for you.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: GridView.builder(
                itemCount: genres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final bool isSelected = selectedIndexes.contains(index);

                  return InkWell(
                    onTap: () => toggleSelection(index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white30,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            genre['icon'],
                            size: 45,
                            color: isSelected
                                ? const Color(0xFF1E88E5)
                                : Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              genre['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF1E88E5)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (selectedIndexes.isEmpty || isLoading)
                      ? null
                      : savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E88E5),
                    disabledBackgroundColor: Colors.white30,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF1E88E5),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
