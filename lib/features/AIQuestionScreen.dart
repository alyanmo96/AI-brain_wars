import 'package:brainwars/services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AIQuestionScreen extends StatefulWidget {
  final String gameKey;
  final String team;

  const AIQuestionScreen({required this.gameKey, required this.team});

  @override
  State<AIQuestionScreen> createState() => _AIQuestionScreenState();
}

class _AIQuestionScreenState extends State<AIQuestionScreen> {
  late Future<DocumentSnapshot> _gameFuture;
  // ignore: unused_field
  String? _questionText, _correctAnswer;

  bool _isLoading = false;

  @override
  void initState() {
    print('🧠 Entered AIQuestionScreen as ${widget.team}');
    super.initState();
    _gameFuture = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameKey)
        .get();
    _generateAIQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _gameFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text("AI Question")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentTurn = data['currentTurn'] ?? 'red';
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text("AI Question")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        print("🔥 AIQuestionScreen loaded");
        print("✅ widget.team: ${widget.team}");
        print("✅ currentTurn: $currentTurn");

        if (widget.team != currentTurn) {
          // Redirect to waiting screen if it's not our turn
          Future.microtask(() {
            Navigator.pushReplacementNamed(
              context,
              '/waiting_for_question',
              arguments: {
                'gameKey': widget.gameKey,
                'team': widget.team,
              },
            );
          });

          return Scaffold(); // empty UI while navigating
        }

        // Continue building the AI question submission screen
        return Scaffold(
          appBar: AppBar(title: Text("AI Question")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("It's ${widget.team}'s turn to ask a question."),
                if (_questionText != null && _correctAnswer != null) ...[
                  SizedBox(height: 20),
                  Text("📘 AI-Generated Question:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_questionText!, textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  Text("✅ Correct Answer (visible only to you):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_correctAnswer!, textAlign: TextAlign.center),
                ],
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: (_questionText == null || _correctAnswer == null)
                      ? null
                      : _submitAIQuestion,
                  child: Text("Submit AI Question"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // void _submitAIQuestion() {
  //   Navigator.pushReplacementNamed(
  //     context,
  //     '/waiting_for_validation',
  //     arguments: {
  //       'gameKey': widget.gameKey,
  //       'team': widget.team,
  //     },
  //   );
  // }

  // Future<void> _generateAIQuestion() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final gameDoc = await FirebaseFirestore.instance
  //         .collection('games')
  //         .doc(widget.gameKey)
  //         .get();
  //     final data = gameDoc.data();
  //     if (data == null) return;

  //     final currentTurn = data['currentTurn'];
  //     if (currentTurn != widget.team) {
  //       // Not this team's turn to ask
  //       Navigator.pushReplacementNamed(context, '/waiting_for_question',
  //           arguments: {
  //             'gameKey': widget.gameKey,
  //             'team': widget.team,
  //           });
  //       return;
  //     }

  //     final newQA = await AIService.generateQuestion();
  //     final questionText = newQA['question']!;
  //     final correctAnswer = newQA['answer']!;

  //     await FirebaseFirestore.instance
  //         .collection('games')
  //         .doc(widget.gameKey)
  //         .update({
  //       'questions': FieldValue.arrayUnion([
  //         {
  //           'text': questionText,
  //           'correctAnswer': correctAnswer,
  //           'askedBy': widget.team,
  //           'timestamp': DateTime.now(),
  //           'image': null,
  //           'validated': true,
  //         }
  //       ])
  //     });
  //     // after adding question, SWITCH turn to opponent!
  //     await FirebaseFirestore.instance
  //         .collection('games')
  //         .doc(widget.gameKey)
  //         .update({
  //       'currentTurn': widget.team == 'red' ? 'blue' : 'red',
  //     });

  //     setState(() {
  //       _questionText = questionText;
  //       _correctAnswer = correctAnswer;
  //     });
  //   } catch (e) {
  //     print("❌ Error generating AI question: $e");
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text("Failed to load question")));
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _generateAIQuestion() async {
    setState(() => _isLoading = true);
    try {
      final newQA = await AIService.generateQuestion();
      setState(() {
        _questionText = newQA['question']!;
        _correctAnswer = newQA['answer']!;
      });
    } catch (e) {
      print("❌ Error generating AI question: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load question")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitAIQuestion() async {
    if (_questionText == null || _correctAnswer == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameKey)
          .update({
        'questions': FieldValue.arrayUnion([
          {
            'text': _questionText!,
            'correctAnswer': _correctAnswer!,
            'askedBy': widget.team,
            'timestamp': DateTime.now(),
            'image': null,
            'validated': true,
          }
        ])
      });

      // switch turn to other team
      await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameKey)
          .update({
        'currentTurn': widget.team == 'red' ? 'blue' : 'red',
      });

      //
      Navigator.pushReplacementNamed(
        context,
        '/waiting_for_validation', // or next appropriate screen
        arguments: {
          'gameKey': widget.gameKey,
          'team': widget.team,
        },
      );
    } catch (e) {
      print("❌ Error submitting AI question: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to submit question")));
    }
  }
}
