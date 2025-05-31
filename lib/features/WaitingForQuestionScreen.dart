import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingForQuestionScreen extends StatefulWidget {
  final String gameKey;
  final String team;

  const WaitingForQuestionScreen({
    required this.gameKey,
    required this.team,
  });

  @override
  State<WaitingForQuestionScreen> createState() =>
      _WaitingForQuestionScreenState();
}

class _WaitingForQuestionScreenState extends State<WaitingForQuestionScreen> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    print('----------------------------WaitingForQuestionScreen---------------team = ' +
        widget.team +
        '-------------------------------------------------------------------------------');
    print('🧠 Entered WaitingForQuestionScreen as ${widget.team}');
    print('🔍 [WaitingForQuestionScreen] widget.team: ${widget.team}');
    _listenForIncomingQuestion();
  }

  void _listenForIncomingQuestion() {
    print(
        '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------1------------------------------------------------------------------------------------');
    _subscription = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameKey)
        .snapshots()
        .listen((snapshot) {
      print(
          '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------2------------------------------------------------------------------------------------');
      if (!snapshot.exists) return;

      print(
          '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------3------------------------------------------------------------------------------------');
      final data = snapshot.data()!;
      final questions = List.from(data['questions'] ?? []);
      final currentTurn = data['currentTurn'] ?? 'red';
      final yourTeam = widget.team;

      print(
          '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------4------------------------------------------------------------------------------------');
      print("📢 yourTeam: $yourTeam, currentTurn: $currentTurn");

      print(
          '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------5------------------------------------------------------------------------------------');
      for (int i = questions.length - 1; i >= 0; i--) {
        final q = Map<String, dynamic>.from(questions[i]);

        print(
            '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------6------------------------------------------------------------------------------------');
        final askedBy = q['askedBy'];
        final correctAnswer = q['correctAnswer'];
        final alreadyAnswered =
            q[yourTeam] != null && (q[yourTeam] as String).trim().isNotEmpty;
        final validated = q['validated'] ?? false;

        final shouldAnswer = askedBy != yourTeam &&
            currentTurn == yourTeam &&
            correctAnswer != null &&
            validated == true &&
            !alreadyAnswered;

        print("🔍 Question check:");
        print(" - askedBy: $askedBy");
        print(" - currentTurn: $currentTurn");
        print(" - yourTeam: $yourTeam");
        print(" - alreadyAnswered: $alreadyAnswered");
        print(" - validated: $validated");
        print(" - correctAnswer: $correctAnswer");
        print(" - shouldAnswer: $shouldAnswer");
        print("💡 q[$yourTeam]: ${q[yourTeam]}");

        if (shouldAnswer) {
          print(
              '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------7------------------------------------------------------------------------------------');
          print("✅ Navigating to AnswerQuestionScreen");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            print(
                '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------8------------------------------------------------------------------------------------');
            if (mounted) {
              print(
                  '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------9------------------------------------------------------------------------------------');
              print('q[\'text\']:' + q['text']);
              print('q[\'validated\']:' + q['validated'].toString());
              Navigator.pushReplacementNamed(
                context,
                '/answer_question',
                arguments: {
                  'gameKey': widget.gameKey,
                  'question': q['text'],
                  'imageUrl': q['image'] ?? '',
                  'team': yourTeam,
                },
              );
            }
            print(
                '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------10------------------------------------------------------------------------------------');
          });
          print(
              '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------11------------------------------------------------------------------------------------');

          return;
        }
        print(
            '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------12------------------------------------------------------------------------------------');
      }

      print(
          '--------------------WaitingForQuestionScreen--------------------_listenForIncomingQuestion------13------------------------------------------------------------------------------------');
      print("⏳ No question ready for $yourTeam yet.");
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Waiting for Question")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text("Waiting for the other team to submit a question..."),
          ],
        ),
      ),
    );
  }
}
