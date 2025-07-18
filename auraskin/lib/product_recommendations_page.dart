import 'package:flutter/material.dart';

class ProductRecommendationsPage extends StatefulWidget {
  final List<dynamic> products;
  final Map<String, dynamic>? modelOutput;

  const ProductRecommendationsPage({
    super.key,
    required this.products,
    this.modelOutput,
  });

  @override
  State<ProductRecommendationsPage> createState() => _ProductRecommendationsPageState();
}

class _ProductRecommendationsPageState extends State<ProductRecommendationsPage> {
  String _sortOption = 'default';
  String _searchText = '';
  String _selectedFilter = 'All';

  late List<dynamic> _displayedProducts;
  final Set<int> _expandedIndices = {};

  List<String> _skinConcernFilters = ['All'];

  @override
  void initState() {
    super.initState();
    _displayedProducts = List.from(widget.products);
    _skinConcernFilters.addAll({
      ...widget.products.map((p) => p['skin_concern'] ?? '').toSet(),
      if (widget.modelOutput != null) ...widget.modelOutput!.keys,
    });
  }

  List<dynamic> _filteredProducts() {
    List<dynamic> filtered = _displayedProducts.where((product) {
      final name = product['product']?.toString().toLowerCase() ?? '';
      final concern = product['skin_concern']?.toString() ?? '';
      final matchesSearch = _searchText.isEmpty || name.contains(_searchText.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || concern == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    if (_sortOption == 'price_asc') {
      filtered.sort((a, b) =>
          (double.tryParse(a['price']?.toString() ?? '') ?? 0)
              .compareTo(double.tryParse(b['price']?.toString() ?? '') ?? 0));
    } else if (_sortOption == 'price_desc') {
      filtered.sort((a, b) =>
          (double.tryParse(b['price']?.toString() ?? '') ?? 0)
              .compareTo(double.tryParse(a['price']?.toString() ?? '') ?? 0));
    } else if (_sortOption == 'rating_asc') {
      filtered.sort((a, b) =>
          (double.tryParse(a['reviews']?.toString() ?? '') ?? 0)
              .compareTo(double.tryParse(b['reviews']?.toString() ?? '') ?? 0));
    } else if (_sortOption == 'rating_desc') {
      filtered.sort((a, b) =>
          (double.tryParse(b['reviews']?.toString() ?? '') ?? 0)
              .compareTo(double.tryParse(a['reviews']?.toString() ?? '') ?? 0));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts();

    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: const Text('Recommended Products'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          if (widget.modelOutput != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Model Prediction:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...widget.modelOutput!.entries.map((entry) {
                    return Text(
                      "${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%",
                      style: const TextStyle(fontSize: 14),
                    );
                  }).toList(),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search product...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sort by Skin Concern",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: SizedBox(),
                value: _selectedFilter,
                items: _skinConcernFilters
                    .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedFilter = value);
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Sort by Price and Rating",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: SizedBox(),
                value: _sortOption,
                items: const [
                  DropdownMenuItem(value: 'default', child: Text("Default")),
                  DropdownMenuItem(value: 'price_asc', child: Text("Price: Low to High")),
                  DropdownMenuItem(value: 'price_desc', child: Text("Price: High to Low")),
                  DropdownMenuItem(value: 'rating_asc', child: Text("Rating: Low to High")),
                  DropdownMenuItem(value: 'rating_desc', child: Text("Rating: High to Low")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                  }
                },
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                final isExpanded = _expandedIndices.contains(index);

                final ingredients = (product['ingredients'] ?? '').toString().split(',').map((e) => e.trim()).toList();
                final displayedIngredients = isExpanded ? ingredients : ingredients.take(3).toList();
                final showToggle = ingredients.length > 3;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Product Name: ",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: product['product'] ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Skin Concern: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: product['skin_concern'] ?? ''),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Type: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: product['type'] ?? ''),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Ingredients: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: displayedIngredients.join(', ')),
                          ],
                        ),
                      ),
                      if (showToggle)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedIndices.remove(index);
                                } else {
                                  _expandedIndices.add(index);
                                }
                              });
                            },
                            child: Text(isExpanded ? 'See less' : 'See more'),
                          ),
                        ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Reviews: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "${(double.tryParse(product['reviews']?.toString() ?? '') ?? 0).toStringAsFixed(1)}/5",),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Price: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "${product['price']?.toString() ?? 'N/A'} BDT (Prices may vary with time)",),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}