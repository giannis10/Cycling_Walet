import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> recognizeTextFromImagePath(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized = await recognizer.processImage(inputImage);
    return recognized.text;
  } finally {
    await recognizer.close();
  }
}
