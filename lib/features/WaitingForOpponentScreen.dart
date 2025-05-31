import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingForOpponentScreen extends StatefulWidget {
  final String gameKey;
  final String team;

  const WaitingForOpponentScreen({
    required this.gameKey,
    required this.team,
  });

  @override
  State<WaitingForOpponentScreen> createState() =>
      _WaitingForOpponentScreenState();
}

class _WaitingForOpponentScreenState extends State<WaitingForOpponentScreen> {
  late Stream<DocumentSnapshot> _gameStream;

  @override
  void initState() {
    super.initState();
    print('----------------------------WaitingForOpponentScreen---------------team = ' +
        widget.team +
        '------------------------------------------------------------------------------');
    print('🧠 Entered WaitingForOpponentScreen as ${widget.team}');

    _gameStream = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameKey)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final opponentTeam = widget.team == 'red' ? 'blue' : 'red';

    return Scaffold(
      appBar: AppBar(title: Text("Waiting for Opponent")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _gameStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final teams = data['teams'] ?? {};
          final opponentPlayers = List.from(teams[opponentTeam] ?? []);

          final isOpponentReady = opponentPlayers.isNotEmpty;

          // If both players joined, move to next screen
          if (isOpponentReady) {
            Future.microtask(() {
              Navigator.pushReplacementNamed(context, '/ai_question',
                  arguments: {
                    'gameKey': widget.gameKey,
                    'team': widget.team,
                  });
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("You're in the ${widget.team.toUpperCase()} team!",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Image.asset(
                  'assets/images/${widget.team == 'red' ? 'RedTeam.png' : 'BlueTeam.png'}',
                  height: 150,
                ),
                SizedBox(height: 40),
                isOpponentReady
                    ? Text("Opponent found! Starting the game...",
                        style: TextStyle(color: Colors.green, fontSize: 18))
                    : Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text("Waiting for opponent to join...",
                              style: TextStyle(fontSize: 16)),
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
