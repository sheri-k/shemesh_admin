import 'package:flutter/material.dart';
import 'package:shemesh_admin/utilities/debug_log.dart';
import 'package:speech_to_text/speech_to_text.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: VoiceInputPage(),
//     );
//   }
// }

class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({super.key});

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage> {
  final SpeechToText speech = SpeechToText();
  final TextEditingController controller = TextEditingController();

  bool speechEnabled = false;
  bool listening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    speechEnabled = await speech.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    await speech.listen(
      localeId: 'he_IL',
      onResult: (result) {
        
        setState(() {
          controller.text = result.recognizedWords;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        });
        debugLog('Recognized: ${result.recognizedWords}');
      },
    );



    setState(() {
      listening = true;
    });
  }

  Future<void> stopListening() async {
    await speech.stop();

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
              controller: controller,
              maxLines: 6,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: "שאלה",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (!speechEnabled)
              const Text("Speech recognition not available"),
            if (speechEnabled)
              ElevatedButton.icon(
                onPressed: listening ? stopListening : startListening,
                icon: Icon(listening ? Icons.stop : Icons.mic),
                label: Text(listening ? "עצור" : "התחל לדבר"),
              ),
          ],
        ),
      ),
    );
  }
}