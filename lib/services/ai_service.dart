import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const _apiKey = ''; // Replace in production

  static Future<Map<String, String>> generateQuestion() async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a trivia question generator. Return ONLY a JSON with keys 'question' and 'answer'. Don't include explanation or anything else. Each call should return a new fun, easy question."
          },
          {"role": "user", "content": "New quiz question please."}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'];

      final Map<String, dynamic> result = jsonDecode(content);
      return {
        'question': result['question'],
        'answer': result['answer'],
      };
    } else {
      print("❌ OpenAI Error: ${response.body}");
      throw Exception('Failed to generate question');
    }
  }
}
