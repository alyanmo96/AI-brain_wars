import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AnswerQuestionScreen extends StatefulWidget {
  final String gameKey;
  final String team;
  final String question;
  final String? imageUrl;

  const AnswerQuestionScreen({
    required this.gameKey,
    required this.team,
    required this.question,
    this.imageUrl,
  });

  @override
  _AnswerQuestionScreenState createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final TextEditingController _answerController = TextEditingController();
  final bool _submitting = false;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkTurn();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        if (!_hasSubmitted) {
          _submitAnswer(timeout: true);
        }
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  void _submitAnswer({bool timeout = false}) async {
    print('🧠 Entered AnswerQuestionScreen as ${widget.team}');
    if (_hasSubmitted) return;
    _hasSubmitted = true;
    _timer?.cancel();

    final answerText = timeout ? 'unanswered' : _answerController.text.trim();

    if (answerText.isEmpty) return;

    final docRef =
        FirebaseFirestore.instance.collection('games').doc(widget.gameKey);
    final doc = await docRef.get();

    if (!doc.exists) return;

    List questions = List.from(doc.data()?['questions'] ?? []);
    if (questions.isEmpty) return;

    final lastIndex = questions.length - 1;
    final lastQuestion = Map<String, dynamic>.from(questions[lastIndex]);
    // 1. Save the answer under the team name
    lastQuestion[widget.team] = answerText;
    lastQuestion['answeredBy'] = widget.team;
    lastQuestion['answer'] = answerText;

    // 2. Validate it
    final correctAnswer = lastQuestion['correctAnswer']?.toString().trim();
    final isCorrect =
        answerText.trim().toLowerCase() == correctAnswer?.toLowerCase();

    lastQuestion['validated'] = true;
    lastQuestion['isCorrect'] = isCorrect;

    // 3. Update score
    final scores = Map<String, dynamic>.from(doc.data()?['scores'] ?? {});
    if (isCorrect) {
      scores[widget.team] = (scores[widget.team] ?? 0) + 1;
    }

    // 4. Switch turn
    final askedBy = lastQuestion['askedBy'];
    final nextTurn = askedBy == 'red' ? 'blue' : 'red';

    print("👀 Validated: ${lastQuestion['validated']}, Turn: $nextTurn");
    // 5. Save everything
    print(lastQuestion.length);
    print(lastQuestion.values);
    print(lastQuestion.keys);
    print(lastQuestion.toString());
    // Final step: Save everything
    questions[lastIndex] = lastQuestion;
    final rounds = Map<String, dynamic>.from(doc.data()?['rounds'] ?? {});
    rounds[widget.team] = (rounds[widget.team] ?? 0) + 1;
    print("✅ Updating game with new turn: $nextTurn");
    print("✅ Full updated question:");
    print(lastQuestion);

    try {
      await docRef.update({
        'questions': questions,
        'scores': scores,
        'rounds': rounds,
        'currentTurn': nextTurn,
      });
      print(
          "✅ Firestore successfully updated with new question + currentTurn.");

      print("✔️ Updated Firestore with currentTurn: $nextTurn");

      print("✅ questions & scores updated");
      print("✅ All fields updated in one transaction");

      print("✅ currentTurn updated to $nextTurn");
    } catch (e) {
      print("❌ Firestore update failed: $e");
    }

    print("✅ questions and scores updated");
    print("✅ currentTurn updated to $nextTurn");

    // 6. Navigate

    if ((rounds['red'] ?? 0) >= 2 && (rounds['blue'] ?? 0) >= 2) {
      Navigator.pushReplacementNamed(context, '/final_result', arguments: {
        'gameKey': widget.gameKey,
      });
      return;
    }
    Navigator.pushReplacementNamed(context, '/waiting_for_validation',
        arguments: {
          'gameKey': widget.gameKey,
          'team': widget.team,
        });
  }

  Future<void> _checkTurn() async {
    final doc = await FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameKey)
        .get();

    if (!doc.exists) return;

    final currentTurn = doc.data()?['currentTurn'] ?? 'red';
    if (currentTurn != widget.team) {
      print(
          "🚫 Not your turn to answer! Redirecting to WaitingForQuestionScreen");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/waiting_for_question',
            arguments: {
              'gameKey': widget.gameKey,
              'team': widget.team,
            });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Answer the Question")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _submitting
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.question,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Image.network(widget.imageUrl!),
                    ),
                  Text("Time left: $_secondsLeft seconds",
                      style: TextStyle(fontSize: 16, color: Colors.red)),
                  SizedBox(height: 10),
                  TextField(
                    controller: _answerController,
                    enabled: !_hasSubmitted && _secondsLeft > 0,
                    decoration: InputDecoration(
                      labelText: "Enter your answer",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitAnswer,
                    child: Text("Submit Answer"),
                  ),
                ],
              ),
      ),
    );
  }
}
