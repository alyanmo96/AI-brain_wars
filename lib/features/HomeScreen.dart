import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    User? user = _auth.currentUser;
    if (user == null) {
      await _auth.signInAnonymously();
      user = _auth.currentUser;
    }
    userId = user!.uid;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('name')) {
      setState(() {
        _nameController.text = doc['name'];
      });
    }
  }

  // Future<void> _saveUserName() async {
  //   if (_nameController.text.trim().isEmpty) return;

  //   User? user = _auth.currentUser;
  //   if (user == null) {
  //     await _auth.signInAnonymously();
  //     user = _auth.currentUser;
  //   }
  //   userId = user!.uid;

  //   await FirebaseFirestore.instance.collection('users').doc(userId).set({
  //     'name': _nameController.text.trim(),
  //   }, SetOptions(merge: true));

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("Name saved!")),
  //   );
  // }

  void _createGame() async {
    /*
    for test choose only 2 cahrs
    */
    // final gameCode = const Uuid().v4().substring(0, 9).toUpperCase();
    final gameCode = const Uuid().v4().substring(0, 2).toUpperCase();

    await FirebaseFirestore.instance.collection('games').doc(gameCode).set({
      'gameKey': gameCode,
      'createdAt': FieldValue.serverTimestamp(),
      'scores': {'red': 0, 'blue': 0},
      'currentTurn': 'red',
      'teams': {'red': [], 'blue': []},
      'questions': [],
      'status': 'waiting',
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Game Created!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Game Code: $gameCode",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: gameCode));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Game code copied!")),
                );
              },
              icon: Icon(Icons.copy),
              label: Text("Copy Code"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Share.share("Join my game using code: $gameCode");
              },
              icon: Icon(Icons.share),
              label: Text("Share Code"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/team_selection', arguments: {
                'gameKey': gameCode,
              });
            },
            child: Text("Start Game"),
          )
        ],
      ),
    );
  }

  // void _showEditNameDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       final tempController =
  //           TextEditingController(text: _nameController.text);

  //       return AlertDialog(
  //         title: Text("Edit Your Name"),
  //         content: TextField(
  //           controller: tempController,
  //           decoration: InputDecoration(
  //             labelText: "Enter name",
  //             border: OutlineInputBorder(),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               _nameController.text = tempController.text;
  //               await _saveUserName();
  //               Navigator.pop(context);
  //               setState(() {});
  //             },
  //             child: Text("Save"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showJoinGameDialog() {
    final TextEditingController tempController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Game Code"),
          content: TextField(
            controller: tempController,
            decoration: InputDecoration(
              hintText: "e.g. AB",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = tempController.text.trim().toUpperCase();
                if (code.isEmpty) return;

                final doc = await FirebaseFirestore.instance
                    .collection('games')
                    .doc(code)
                    .get();

                if (doc.exists) {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/team_selection', arguments: {
                    'gameKey': code,
                  });
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Game code not found")),
                  );
                }
              },
              child: Text("Join"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("🎮 AI Quiz Game"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            tooltip: "Profile",
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple, width: 2),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 30),
                  SizedBox(height: 8),
                  Text(
                    "Welcome, ${_nameController.text}!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            GestureDetector(
              onTap: _createGame,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                margin: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    "🎮 Start New Game",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 40),
            GestureDetector(
              onTap: () => _showJoinGameDialog(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                margin: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    "Join Game 🎮",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
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
