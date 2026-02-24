import 'package:flutter/material.dart';

class GenreScreen extends StatefulWidget {
  const GenreScreen({super.key});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  final List<Map<String, dynamic>> genres = [
    {'title': 'Society & Culture', 'icon': Icons.science},
    {'title': 'Science & Mathematics', 'icon': Icons.menu_book},
    {'title': 'Health', 'icon': Icons.public},
    {'title': 'Education & Reference', 'icon': Icons.movie},
    {'title': 'Computers & Internet', 'icon': Icons.music_note},
    {'title': 'Sports', 'icon': Icons.sports_esports},
    {'title': 'Business & Finance', 'icon': Icons.emoji_events},
    {'title': 'Entertainment & Music', 'icon': Icons.lightbulb},
    {'title': 'Family & Relationships', 'icon': Icons.computer},
    {'title': 'Politics & Government', 'icon': Icons.palette},
  ];

  final List<int> selectedIndexes = [];

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E88E5), Color(0xFF42A5F5)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text(
              'Choose Your Genre',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select at least one genre to continue',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Genre Selection
            Expanded(
              child: GridView.builder(
                itemCount: genres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  final bool isSelected = selectedIndexes.contains(index);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => toggleSelection(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.lightBlueAccent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            genre['icon'],
                            size: 40,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0083B0),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            genre['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue Button
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedIndexes.isEmpty
                      ? null
                      : () {
                    final selectedGenres = selectedIndexes
                        .map((i) => genres[i]['title'] as String)
                        .toList();

                    Navigator.pushNamed(
                      context,
                      '/home',
                      arguments: selectedGenres,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16
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
