import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeamSelectionScreen extends StatelessWidget {
  final String gameKey;

  TeamSelectionScreen({required this.gameKey});
  Future<void> _selectTeam(BuildContext context, String team) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final userName = userDoc.data()?['name'] ?? 'Player';

    final gameDocRef =
        FirebaseFirestore.instance.collection('games').doc(gameKey);
    final gameSnapshot = await gameDocRef.get();

    if (!gameSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game not found')),
      );
      return;
    }

    final data = gameSnapshot.data()!;
    final teams = Map<String, dynamic>.from(data['teams'] ?? {});
    final redPlayers = List.from(teams['red'] ?? []);
    final bluePlayers = List.from(teams['blue'] ?? []);

    // Prevent duplicate join
    final alreadyInRed = redPlayers.any((p) => p['id'] == currentUserId);
    final alreadyInBlue = bluePlayers.any((p) => p['id'] == currentUserId);

    if (alreadyInRed && team == 'red' || alreadyInBlue && team == 'blue') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You're already in $team team.")),
      );
      return;
    }

    if (alreadyInRed || alreadyInBlue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can't switch teams once joined.")),
      );
      return;
    }

    // Add to the team
    final updatedPlayers = team == 'red' ? redPlayers : bluePlayers;
    updatedPlayers.add({'id': currentUserId, 'name': userName});

    await gameDocRef.update({
      'teams.$team': updatedPlayers,
    });

    Navigator.pushNamed(context, '/waiting_for_opponent', arguments: {
      'gameKey': gameKey,
      'team': team,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Your Team")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Choose the team you want to play with",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            Expanded(
              child: Row(
                children: [
                  _teamCard(
                      context, 'red', 'assets/images/RedTeam.png', Colors.red),
                  SizedBox(width: 20),
                  _teamCard(context, 'blue', 'assets/images/BlueTeam.png',
                      Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamCard(
      BuildContext context, String team, String imagePath, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTeam(context, team),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // ignore: deprecated_member_use
          color: color.withOpacity(0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 120),
              SizedBox(height: 20),
              Text(team.toUpperCase(),
                  style: TextStyle(fontSize: 24, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
