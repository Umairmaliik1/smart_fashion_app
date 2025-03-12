import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String age = '';
  String gender = 'Male'; // default selection
  String contact = '';
  String address = '';
  String city = 'Islamabad'; // default city
  String province = 'Punjab'; // default province
  String paymentMethod = 'Cash on Delivery'; // fixed payment method

  bool isPlacingOrder = false;

  // Lists of cities and provinces in Pakistan.
  final List<String> cities = [
    'Islamabad',
    'Lahore',
    'Karachi',
    'Peshawar',
    'Faisalabad',
    'Rawalpindi'
  ];

  final List<String> provinces = [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
  ];

  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isPlacingOrder = true;
      });

      // Get the current cart details.
      final cart = Provider.of<CartModel>(context, listen: false);
      double total = 0.0;
      for (var item in cart.items) {
        String priceStr = item['price']!.replaceAll('\$', '');
        total += double.tryParse(priceStr) ?? 0;
      }

      // Retrieve the current user UID.
      final user = FirebaseAuth.instance.currentUser;
      String? userId = user?.uid;

      // Build the order data including the userId.
      Map<String, dynamic> orderData = {
        'name': name,
        'age': age,
        'gender': gender,
        'contact': contact,
        'address': address,
        'city': city,
        'province': province,
        'paymentMethod': paymentMethod,
        'total': total,
        'items': cart.items,
        'orderTime': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      try {
        // Save the order to Firestore in the "orders" collection.
        await FirebaseFirestore.instance.collection('orders').add(orderData);
        // Optionally clear the cart.
        cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );
        Navigator.pop(context); // Return to the previous screen.
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to place order: $e")),
        );
      } finally {
        setState(() {
          isPlacingOrder = false;
        });
      }
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goToCart(BuildContext context) {
    Navigator.pushNamed(context, '/cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with gradient background, cart and logout buttons.
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, size: 28),
            onPressed: () => _goToCart(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      // Gradient background for the screen.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Confirm Your Order",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => name = value,
                      validator: (value) =>
                      (value == null || value.isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    // Age Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: const Icon(Icons.cake),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => age = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Age must be a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: gender,
                      items: <String>['Male', 'Female', 'Other']
                          .map((String genderValue) => DropdownMenuItem<String>(
                        value: genderValue,
                        child: Text(genderValue),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Contact Number Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => contact = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your contact number';
                        }
                        if (value.length < 10) {
                          return 'Enter a valid contact number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => address = value,
                      validator: (value) =>
                      (value == null || value.isEmpty) ? 'Please enter your address' : null,
                    ),
                    const SizedBox(height: 16),
                    // City Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: city,
                      items: cities
                          .map((city) => DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          city = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Province Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Province',
                        prefixIcon: const Icon(Icons.map),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: province,
                      items: provinces
                          .map((prov) => DropdownMenuItem<String>(
                        value: prov,
                        child: Text(prov),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          province = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Payment Method Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: const Icon(Icons.payment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      value: paymentMethod,
                      items: const [
                        DropdownMenuItem(
                          value: 'Cash on Delivery',
                          child: Text('Cash on Delivery'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    isPlacingOrder
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _placeOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text(
                          "Place Order",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
