import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinalResultScreen extends StatelessWidget {
  final String gameKey;

  const FinalResultScreen({required this.gameKey});

  Future<Map<String, dynamic>> _fetchGameData() async {
    final doc =
        await FirebaseFirestore.instance.collection('games').doc(gameKey).get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🏆 Game Summary")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchGameData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final gameData = snapshot.data!;
          final scores = Map<String, dynamic>.from(gameData['scores'] ?? {});
          final questions = List<Map<String, dynamic>>.from(
              (gameData['questions'] as List<dynamic>?)
                      ?.map((q) => Map<String, dynamic>.from(q)) ??
                  []);

          final winner = scores['red'] == scores['blue']
              ? "It's a tie!"
              : scores['red'] > scores['blue']
                  ? "Red Team Wins!"
                  : "Blue Team Wins!";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(winner,
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(
                    "Final Score: 🔴 ${scores['red'] ?? 0} vs 🔵 ${scores['blue'] ?? 0}",
                    style: TextStyle(fontSize: 20)),
                Divider(height: 30, thickness: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (_, index) {
                      final q = questions[index];
                      final askedBy = q['askedBy'] ?? 'unknown';
                      final answeredBy = q['answeredBy'] ?? 'unknown';
                      final isCorrect = q['isCorrect'] ?? false;
                      final answer = q['answer'] ?? 'N/A';

                      return Card(
                        color: isCorrect ? Colors.green[100] : Colors.red[100],
                        child: ListTile(
                          title: Text(q['text'] ?? 'Question $index'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("🧠 Asked by: $askedBy"),
                              Text("✋ Answered by: $answeredBy"),
                              Text("✅ Answer: $answer"),
                              Text(
                                  "🎯 Result: ${isCorrect ? "Correct" : "Incorrect"}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text("Play Again"),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (_) => false);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.home),
                      label: Text("Home"),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (_) => false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
