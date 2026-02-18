import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final List<String> genres;

  const ProfileScreen({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFF1E88E5),
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white,)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selected Genres:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: genres.map((g) => Chip(label: Text(g))).toList(),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Save genres to database here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Genres saved to database!")),
                  );
                },
                label: const Text("Save Preferences"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size( 80, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}