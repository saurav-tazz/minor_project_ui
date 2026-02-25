// import 'package:flutter/material.dart';
//
// class QuestionSelectionScreen extends StatelessWidget {
//   const QuestionSelectionScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Temporary dummy data
//     final List<String> questions = [
//       "What is the capital of France?",
//       "Who developed Flutter?",
//       "What is 2 + 2?",
//       "Which planet is known as the Red Planet?",
//       "Who wrote Hamlet?"
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E88E5),
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Select Question",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: ListView.builder(
//               itemCount: questions.length,
//               itemBuilder: (context, index) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 12),
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(16),
//                     onTap: () {
//                       Navigator.pushNamed(context, '/matchroom');
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.08),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             backgroundColor: const Color(0xFF1E88E5),
//                             child: Text(
//                               "${index + 1}",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Text(
//                               questions[index],
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           const Icon(
//                             Icons.arrow_forward_ios_rounded,
//                             size: 16,
//                             color: Color(0xFF1E88E5),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//asdgiashfkj
