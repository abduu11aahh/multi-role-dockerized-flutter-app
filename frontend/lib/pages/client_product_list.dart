import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientProductList extends StatefulWidget {
  @override
  _ClientProductListState createState() => _ClientProductListState();
}

class _ClientProductListState extends State<ClientProductList> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  Future<void> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://flutter-app-api-o5zh.onrender.com/products'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(responseData);
          products.forEach((product) {
            if (product['price'] is String) {
              product['price'] = double.tryParse(product['price']);
            }
          });
        });
      } else {
        print('Failed to load products: ${response.statusCode}');
      }
    } catch (error) {
      print('Error loading products: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Product List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductItem(product: product);
        },
      ),
    );
  }
}

class ProductItem extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final String name = product['name'];
    final double price = (product['price'] is String)
        ? double.tryParse(product['price']) ?? 0.0
        : product['price'];
    final String description = product['description'];
    final String imageUrl = product['imageUrl'];

    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 150.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }
}
