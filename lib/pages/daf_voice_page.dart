import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';
import 'package:docx_template/docx_template.dart';
import 'package:path_provider/path_provider.dart';




class DafVoicePage extends StatefulWidget {
  const DafVoicePage({super.key});

  @override
  State<DafVoicePage> createState() => _DafVoicePageState();
}

class _DafVoicePageState extends State<DafVoicePage> {
  final SpeechToText speech = SpeechToText();

  bool speechReady = false;
  bool listening = false;
  String activeField = "";

  final Map<String, TextEditingController> fields = {
    "daf": TextEditingController(),
    "question": TextEditingController(),
    "a1": TextEditingController(),
    "a2": TextEditingController(),
    "a3": TextEditingController(),
    "a4": TextEditingController(),
    "correct": TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    speechReady = await speech.initialize();
    setState(() {});
  }

  Future<void> startListening(String fieldKey) async {
    activeField = fieldKey;

    await speech.listen(
      localeId: 'he_IL',
      onResult: (result) {
        setState(() {
          fields[fieldKey]!.text = result.recognizedWords;
          fields[fieldKey]!.selection = TextSelection.fromPosition(
            TextPosition(offset: fields[fieldKey]!.text.length),
          );
        });
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
      activeField = "";
    });
  }

  Widget buildVoiceField({
    required String title,
    required String keyName,
    int maxLines = 1,
  }) {
    final isActive = activeField == keyName && listening;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: !speechReady
                      ? null
                      : isActive
                          ? stopListening
                          : () => startListening(keyName),
                  icon: Icon(isActive ? Icons.stop : Icons.mic),
                  label: Text(isActive ? "עצור" : "דבר"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fields[keyName],
              maxLines: maxLines,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveData() {
    print("Daf: ${fields["daf"]!.text}");
    print("Question: ${fields["question"]!.text}");
    print("A1: ${fields["a1"]!.text}");
    print("A2: ${fields["a2"]!.text}");
    print("A3: ${fields["a3"]!.text}");
    print("A4: ${fields["a4"]!.text}");
    print("Correct: ${fields["correct"]!.text}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved")),
    );
  }

  Future<void> saveToDocx() async {
  final bytes = await File('assets/template.docx').readAsBytes();
  final docx = await DocxTemplate.fromBytes(bytes);

  final content = Content()
    ..add(TextContent("daf", fields["daf"]!.text))
    ..add(TextContent("question", fields["question"]!.text))
    ..add(TextContent("a1", fields["a1"]!.text))
    ..add(TextContent("a2", fields["a2"]!.text))
    ..add(TextContent("a3", fields["a3"]!.text))
    ..add(TextContent("a4", fields["a4"]!.text))
    ..add(TextContent("correct", fields["correct"]!.text));

  final generated = await docx.generate(content);

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/daf_question.docx');

  await file.writeAsBytes(generated!);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("DOCX saved: ${file.path}")),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daf Question Voice Entry"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildVoiceField(title: "דף חדש", keyName: "daf"),
            buildVoiceField(
              title: "שאלה",
              keyName: "question",
              maxLines: 4,
            ),
            buildVoiceField(title: "תשובה ראשונה", keyName: "a1"),
            buildVoiceField(title: "תשובה שניה", keyName: "a2"),
            buildVoiceField(title: "תשובה שלישית", keyName: "a3"),
            buildVoiceField(title: "תשובה רביעית", keyName: "a4"),
            buildVoiceField(title: "תשובה נכונה", keyName: "correct"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveToDocx,
              child: const Text("Save to DocX"),
            ),
          ],
        ),
      ),
    );
  }
}