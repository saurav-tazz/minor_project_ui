import 'package:flutter/material.dart';
import 'package:quiz_duel/widgets/logo.dart';


class HomeScreen extends StatelessWidget {
  final List<String> genres;
  const HomeScreen({super.key, required this.genres});

  void _navigateTo(BuildContext context, String route, List<String>? genres) {
    Navigator.pushNamed(
      context,
      route,
      arguments: genres,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final genres = ModalRoute.of(context)!.settings.arguments as List<String>?;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quiz Arena",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        automaticallyImplyLeading: false,
        // for later after logo is decided
        // leading: Padding(
        //   padding: const EdgeInsets.all(8.0), // optional spacing
        //   child: Image.asset(
        //     'assets/logo.png',
        //     fit: BoxFit.contain,
        //   ),
        // ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Logo(
            size: 70,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white,),
            onPressed: () {
              _navigateTo(context, '/profile', genres); // future profile screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildModeCard(
              context,
              "Quick Match",
              Icons.flash_on,
                  () => _navigateTo(context, '/matchroom', genres),
            ),
            _buildModeCard(
              context,
              "Challenge Friend",
              Icons.group,
                  () => _navigateTo(context, '/matchroom', genres), // later friend logic
            ),
            _buildModeCard(
              context,
              "Practice",
              Icons.school,
                  () => _navigateTo(context, '/matchroom', genres),
            ),
            _buildModeCard(
              context,
              "Profile",
              Icons.person,
                  () => _navigateTo(context, '/profile', genres),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF1E88E5)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}