import 'package:flutter/material.dart';
import 'product_recommendations_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SkinTypeSelectionPage extends StatelessWidget {
  final String baseUrl;

  const SkinTypeSelectionPage({super.key, required this.baseUrl});

  Future<List<dynamic>> fetchProducts(String skinType) async {
    final url = Uri.parse(
        '$baseUrl/analysis/skin_type_recommendations?type=$skinType');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['recommended_products'] ?? [];
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  void _handleSelection(BuildContext context, String skinType) async {
    try {
      final products = await fetchProducts(skinType);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductRecommendationsPage(products: products),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Skin Type')),
      body: Stack(
        children: [
          Image.asset(
            'assets/background.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          //overlay to make buttons readable
          Container(
            color: Colors.white.withOpacity(0.2),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.withOpacity(0.8),
                    // semi-transparent
                    padding: const EdgeInsets.all(30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15), // rounded corners
                    ),
                  ),
                  onPressed: () => _handleSelection(context, "Dry"),
                  child: const Text(
                    "Dry Skin",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.withOpacity(0.8),
                    // semi-transparent
                    padding: const EdgeInsets.all(30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15), // rounded corners
                    ),
                  ),
                  onPressed: () => _handleSelection(context, "Oily"),
                  child: const Text(
                    "Oily Skin",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}