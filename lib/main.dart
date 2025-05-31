import 'package:brainwars/features/WaitingForValidationScreen.dart';
import 'package:brainwars/features/WaitingForOpponentScreen.dart';
import 'package:brainwars/features/WaitingForQuestionScreen.dart';
import 'package:brainwars/features/AnswerQuestionScreen.dart';
import 'package:brainwars/features/TeamSelectionScreen.dart';
import 'package:brainwars/features/FinalResultScreen.dart';
import 'package:brainwars/features/AIQuestionScreen.dart';
import 'package:brainwars/features/ProfileScreen.dart';
import 'package:brainwars/features/HomeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('Flutter app started'); // Add this

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainWars',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/team_selection') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TeamSelectionScreen(gameKey: args['gameKey']),
          );
        }

        if (settings.name == '/waiting_for_opponent') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => WaitingForOpponentScreen(
              gameKey: args['gameKey'],
              team: args['team'],
            ),
          );
        }

        if (settings.name == '/ai_question') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AIQuestionScreen(
              gameKey: args['gameKey'],
              team: args['team'],
            ),
          );
        }

        if (settings.name == '/waiting_for_question') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => WaitingForQuestionScreen(
              gameKey: args['gameKey'],
              team: args['team'],
            ),
          );
        }

        if (settings.name == '/answer_question') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AnswerQuestionScreen(
              gameKey: args['gameKey'],
              team: args['team'],
              question: args['question'],
              imageUrl: args['imageUrl'],
            ),
          );
        }

        if (settings.name == '/waiting_for_validation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => WaitingForValidationScreen(
              gameKey: args['gameKey'],
              team: args['team'],
            ),
          );
        }

        if (settings.name == '/final_result') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => FinalResultScreen(gameKey: args['gameKey']),
          );
        }

        if (settings.name == '/profile') {
          return MaterialPageRoute(
            builder: (_) => ProfileScreen(),
          );
        }

        return null;
      },
    );
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showHelloMessage(BuildContext context) {
  showSnackBar(context, "Hello! Welcome to BrainWars!");
}
