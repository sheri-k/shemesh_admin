// pubspec.yaml
// dependencies:
//   flutter:
//     sdk: flutter

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: VoiceQuestionPage(),
//     );
//   }
// }

class VoiceQuestionPage extends StatefulWidget {
  @override
  State<VoiceQuestionPage> createState() => _VoiceQuestionPageState();
}

class _VoiceQuestionPageState extends State<VoiceQuestionPage> {
  final TextEditingController questionController = TextEditingController();

  dynamic recognition;
  bool listening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() {
    final dynamic speechRecognition = js_util.getProperty(
      html.window,
      'webkitSpeechRecognition',
    );

    if (speechRecognition == null) {
      print("Speech recognition not supported");
      return;
    }

    recognition = js_util.callConstructor(speechRecognition, []);

    js_util.setProperty(recognition, 'lang', 'he-IL');
    js_util.setProperty(recognition, 'continuous', false);
    js_util.setProperty(recognition, 'interimResults', true);

    js_util.setProperty(recognition, 'onresult', (event) {
      final results = js_util.getProperty(event, 'results');
      final firstResult = results[0];
      final firstAlt = firstResult[0];
      final transcript = js_util.getProperty(firstAlt, 'transcript');

      setState(() {
        questionController.text = transcript;
      });
    });

    js_util.setProperty(recognition, 'onend', (_) {
      setState(() {
        listening = false;
      });
    });
  }

  // void initSpeech() {
  //   final speechRecognition =
  //       js_util.getProperty(html.window, 'webkitSpeechRecognition');

  //   recognition = js_util.callConstructor(speechRecognition, []);

  //   js_util.setProperty(recognition, 'lang', 'he-IL');
  //   js_util.setProperty(recognition, 'continuous', false);
  //   js_util.setProperty(recognition, 'interimResults', true);

  //   recognition.onresult = (event) {
  //     final results = js_util.getProperty(event, 'results');
  //     String transcript = "";

  //     for (int i = 0; i < results.length; i++) {
  //       final result = results[i];
  //       final first = result[0];
  //       transcript += js_util.getProperty(first, 'transcript');
  //     }

  //     setState(() {
  //       questionController.text = transcript;
  //       questionController.selection = TextSelection.fromPosition(
  //         TextPosition(offset: questionController.text.length),
  //       );
  //     });
  //   };

  //   recognition.onend = (_) {
  //     setState(() {
  //       listening = false;
  //     });
  //   };
  // }

  void startListening() {
    recognition.start();
    setState(() {
      listening = true;
    });
  }

  void stopListening() {
    recognition.stop();
    setState(() {
      listening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hebrew Voice Input"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: questionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "שאלה",
                border: OutlineInputBorder(),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: listening ? stopListening : startListening,
              icon: Icon(listening ? Icons.stop : Icons.mic),
              label: Text(listening ? "עצור" : "דבר"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
