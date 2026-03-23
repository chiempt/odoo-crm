import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannedLeadData {
  final String name;
  final String email;
  final String phone;
  final String company;
  final String rawText;

  ScannedLeadData({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.rawText,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'notes': rawText,
    };
  }
}

class SmartScanProvider with ChangeNotifier {
  bool _isProcessing = false;
  String? _error;
  ScannedLeadData? _scannedData;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  ScannedLeadData? get scannedData => _scannedData;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> scanBusinessCard(ImageSource source) async {
    _isProcessing = true;
    _error = null;
    _scannedData = null;
    notifyListeners();

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      _scannedData = _parseBusinessCard(recognizedText.text);
      
    } catch (e) {
      _error = 'Failed to scan card: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  ScannedLeadData _parseBusinessCard(String text) {
    debugPrint('Parsing text: $text');
    final lines = text.split('\n');
    
    String name = '';
    String email = '';
    String phone = '';
    String company = '';

    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final phoneRegex = RegExp(r'(\+?\d[\d\s\-\(\)]{8,}\d)');

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (email.isEmpty && emailRegex.hasMatch(trimmedLine)) {
        email = emailRegex.firstMatch(trimmedLine)?.group(0) ?? '';
        continue;
      }

      if (phone.isEmpty && phoneRegex.hasMatch(trimmedLine)) {
        phone = phoneRegex.firstMatch(trimmedLine)?.group(0) ?? '';
        continue;
      }

      // Simple heuristic: First non-phone, non-email line might be name or company
      if (name.isEmpty) {
        name = trimmedLine;
      } else if (company.isEmpty) {
        company = trimmedLine;
      }
    }

    return ScannedLeadData(
      name: name,
      email: email,
      phone: phone,
      company: company,
      rawText: text,
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
