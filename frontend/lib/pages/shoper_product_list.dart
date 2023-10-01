import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ShopperProductList extends StatefulWidget {
  @override
  _ShopperProductListState createState() => _ShopperProductListState();
}

class _ShopperProductListState extends State<ShopperProductList> {
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

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _addProduct() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isUploading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Product'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                _imageFile = File(pickedFile.path);
                              });
                            }
                          },
                          child: Text('Select Image'),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          _imageFile != null
                              ? 'Image Selected'
                              : 'No image selected',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Product Name'),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Product Price'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: 'Product Description'),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          final price =
                              double.tryParse(_priceController.text.trim());
                          final description =
                              _descriptionController.text.trim();

                          if (name.isNotEmpty &&
                              price != null &&
                              description.isNotEmpty &&
                              _imageFile != null) {
                            setState(() {
                              isUploading = true;
                            });

                            final request = http.MultipartRequest(
                              'POST',
                              Uri.parse(
                                  'https://flutter-app-api-o5zh.onrender.com/addproduct'),
                            );

                            request.files.add(
                              await http.MultipartFile.fromPath(
                                'image',
                                _imageFile!.path,
                              ),
                            );

                            request.fields['name'] = name;
                            request.fields['price'] = price.toString();
                            request.fields['description'] = description;

                            final response = await request.send();

                            if (response.statusCode == 200) {
                              final newProduct = {
                                'id': products.length + 1,
                                'name': name,
                                'price': price,
                                'description': description,
                                'imageUrl': _imageFile!.path,
                              };
                              setState(() {
                                products.add(newProduct);
                                isUploading = false;
                              });

                              await getProducts();

                              _nameController.clear();
                              _priceController.clear();
                              _descriptionController.clear();
                              setState(() {
                                _imageFile = null;
                              });
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to add product. Please try again later.'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please enter valid product details and select an image.'),
                              ),
                            );
                          }
                        },
                  child: Text('Add Product'),
                ),
                TextButton(
                  onPressed: () {
                    _nameController.clear();
                    _priceController.clear();
                    _descriptionController.clear();
                    setState(() {
                      _imageFile = null;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopper Product List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductItem(
            name: product['name'],
            price: product['price'],
            description: product['description'],
            imageUrl: product['imageUrl'],
          );
        },
      ),
    );
  }
}

class ProductItem extends StatelessWidget {
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  ProductItem({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
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
