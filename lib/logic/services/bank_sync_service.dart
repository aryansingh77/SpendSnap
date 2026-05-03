import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../data/models/transaction_model.dart';

class BankSyncService {
  /// Makes a REAL network request to fetch dynamic data
  /// (Using a public JSON API to simulate a bank statement endpoint)
  static Future<List<TransactionModel>> fetchRecentBankTransactions(String userId) async {
    try {
      final random = Random();
      // Fetch a random cart to get DIFFERENT data every time you click the button (1 to 20)
      final randomCartId = random.nextInt(20) + 1;
      
      // 1. Make a real HTTP GET request to a public API endpoint using package:http
      final response = await http.get(Uri.parse('https://dummyjson.com/carts/$randomCartId'));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch from API: ${response.statusCode}');
      }

      // 2. Decode the real JSON response
      final decoded = jsonDecode(response.body);

      final List<dynamic> products = decoded['products'] ?? [];
      final now = DateTime.now();

      // 3. Map the remote API data into our App's Transaction Models
      return products.map((item) {
        final String title = item['title']?.toString().toUpperCase() ?? 'MERCHANT';
        // Convert API prices to reasonable INR amounts
        final double amount = (item['price'] as num).toDouble() * 80;

        return TransactionModel(
          id: 'api_sync_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
          userId: userId,
          title: title,
          amount: amount,
          type: TransactionType.expense,
          category: _guessCategory(title),
          date: now.subtract(Duration(days: random.nextInt(5))),
          isRecurring: false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // A smarter string-matching engine to categorize dummy API items realistically
  static String _guessCategory(String title) {
    title = title.toLowerCase();

    // Food & Dining
    final foodKeywords = ['food', 'meat', 'grocery', 'meal', 'cookie', 'biscuit', 'snack', 'drink', 'water', 'coffee', 'juice', 'cafe', 'restaurant', 'mcdonald'];
    if (foodKeywords.any((word) => title.contains(word))) {
      return 'Food & Dining';
    }

    // Shopping
    final shoppingKeywords = ['perfume', 'cream', 'shirt', 'dress', 'shoe', 'bottle', 'bag', 'watch', 'lipstick', 'makeup', 'apparel', 'nail', 'powder', 'essence', 'sleeve', 'jeans', 'sneaker', 'leather'];
    if (shoppingKeywords.any((word) => title.contains(word))) {
      return 'Shopping';
    }

    // Entertainment
    final entertainmentKeywords = ['toy', 'game', 'movie', 'book', 'play', 'subscription', 'music', 'tv', 'laptop', 'charger', 'phone'];
    if (entertainmentKeywords.any((word) => title.contains(word))) {
      return 'Entertainment';
    }

    // Health
    final healthKeywords = ['health', 'vitamin', 'pill', 'medicine', 'pharmacy', 'care', 'soap', 'serum', 'lotion'];
    if (healthKeywords.any((word) => title.contains(word))) {
      return 'Health';
    }

    // Bills & Utilities
    final utilityKeywords = ['bill', 'electric', 'water', 'internet', 'mobile'];
    if (utilityKeywords.any((word) => title.contains(word))) {
      return 'Bills & Utilities';
    }
    
    // Transport 
    final transportKeywords = ['uber', 'ola', 'taxi', 'train', 'flight', 'gas', 'fuel', 'petrol', 'car', 'bike'];
    if (transportKeywords.any((word) => title.contains(word))) {
      return 'Transport';
    }

    return 'Other';
  }
}


