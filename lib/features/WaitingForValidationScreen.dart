import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingForValidationScreen extends StatefulWidget {
  final String gameKey;
  final String team;

  const WaitingForValidationScreen({
    required this.gameKey,
    required this.team,
  });

  @override
  _WaitingForValidationScreenState createState() =>
      _WaitingForValidationScreenState();
}

class _WaitingForValidationScreenState
    extends State<WaitingForValidationScreen> {
  late Stream<DocumentSnapshot> _gameStream;
  bool _navigated = false;

  @override
  void initState() {
    print('----------------------------WaitingForValidationScreen---------------team = ' +
        widget.team +
        '-------------------------------------------------------------------------------');

    print('🧠 Entered WaitingForValidationScreen as ${widget.team}');

    super.initState();
    _gameStream = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameKey)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Validating Answer...")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _gameStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          final questions = List.from(gameData['questions'] ?? []);

          if (questions.isEmpty) {
            return Center(child: Text("No question data."));
          }

          final lastQuestion = Map<String, dynamic>.from(questions.last);
          final currentTurn = gameData['currentTurn'] ?? 'red';
          final yourTeam = widget.team;
          final opponentTeam = yourTeam == 'red' ? 'blue' : 'red';

          final validated = lastQuestion['validated'] == true;
          final askedBy = lastQuestion['askedBy'];
          final opponentAnswered = lastQuestion.containsKey(opponentTeam) &&
              lastQuestion[opponentTeam].toString().isNotEmpty;

          print("📍 VALIDATION CHECK");
          print("✔ validated: $validated");
          print("✔ askedBy: $askedBy");
          print("✔ currentTurn: $currentTurn");
          print("✔ yourTeam: $yourTeam");
          print("✔ opponentAnswered: $opponentAnswered");

          if (!_navigated && validated) {
            _navigated = true;

            // Game end condition
            if (questions.length >= 4) {
              print("🏁 Game finished. Moving to final results.");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/final_result',
                    arguments: {'gameKey': widget.gameKey});
              });
            } else {
              final justAsked = askedBy == yourTeam;
              final isNowMyTurn = currentTurn == yourTeam;

              if (justAsked && isNowMyTurn) {
                print("⏳ I just asked, but it's still my turn (waiting).");
                return Center(
                    child: Text("Waiting for the other team to answer..."));
              }

              if (askedBy == yourTeam && !opponentAnswered && !validated) {
                print("⛔ Opponent team hasn't answered yet. Staying here.");
                return Center(
                    child: Text("Waiting for the other team to answer..."));
              }

              print("➡ Proceeding to check whose turn it is...");

              // Navigation
              final nextRoute =
                  (isNowMyTurn) ? '/ai_question' : '/waiting_for_question';

              print("🚀 Navigating to $nextRoute");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, nextRoute, arguments: {
                  'gameKey': widget.gameKey,
                  'team': widget.team,
                });
              });
            }
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Waiting for validation..."),
              ],
            ),
          );
        },
      ),
    );
  }
}
