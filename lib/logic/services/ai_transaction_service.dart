import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class AiTransactionService {
  // TODO: Replace with a real API key from Google AI Studio (https://aistudio.google.com/)
  static const String _apiKey = 'REPLACE_ME';

  final GenerativeModel _textModel;
  final GenerativeModel _visionModel;

  AiTransactionService()
      : _textModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey),
        _visionModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

  Future<TransactionModel> extractFromText(String text, String userId) async {
    final prompt = '''
      You are a smart personal finance assistant. Convert the user's text into a JSON object.
      User Text: "$text"
      
      Required format:
      {
        "title": "Short descriptive title",
        "amount": (numeric value, positive),
        "type": "income" or "expense",
        "category": "Food & Dining", "Transport", "Shopping", "Entertainment", "Health", "Bills & Utilities", "Other"
      }
      
      Only return valid JSON, no markdown formatting, no explanations.
    ''';

    try {
      final response = await _textModel.generateContent([Content.text(prompt)]);

      // Clean up potential markdown formatting (```json) just in case
      String rawJson = response.text ?? '{}';
      rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();

      final data = jsonDecode(rawJson);

      return TransactionModel(
        id: const Uuid().v4(),
        userId: userId,
        title: data['title'] ?? 'Smart Entry',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        category: data['category'] ?? 'Other',
        date: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse text via AI: $e');
    }
  }

  Future<TransactionModel> extractFromReceipt(List<int> imageBytes, String userId) async {
    final prompt = '''
      Extract the transaction details from this receipt image.
      
      Required format:
      {
        "title": "Store name or short description",
        "amount": (total numeric value, positive),
        "type": "expense",
        "category": "Food & Dining", "Transport", "Shopping", "Entertainment", "Health", "Bills & Utilities", "Other"
      }
      
      Only return valid JSON, no markdown formatting, no explanations.
    ''';

    try {
      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await _visionModel.generateContent([
        Content.multi([TextPart(prompt), imagePart])
      ]);

      String rawJson = response.text ?? '{}';
      rawJson = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();

      final data = jsonDecode(rawJson);

      return TransactionModel(
        id: const Uuid().v4(),
        userId: userId,
        title: data['title'] ?? 'Scanned Receipt',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        type: TransactionType.expense,
        category: data['category'] ?? 'Other',
        date: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to read receipt via AI: $e');
    }
  }
}

