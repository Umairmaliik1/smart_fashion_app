import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Stream that fetches items whose category is either 'upperTop' or 'lowerBottom'
    final Stream<QuerySnapshot<Map<String, dynamic>>> clothingStream =
    FirebaseFirestore.instance
        .collection('clothingItems')
        .where('category', whereIn: ['upperTop', 'lowerBottom'])
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Fashion Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Cart button with badge.
          Consumer<CartModel>(
            builder: (context, cart, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart, size: 28),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              );
            },
          ),
          // Logout button.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.deepPurple,
          child: ListView(
            children: [
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const DrawerHeader(
                      decoration: BoxDecoration(color: Colors.deepPurple),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return DrawerHeader(
                      decoration: const BoxDecoration(color: Colors.deepPurple),
                      child: Text(
                        FirebaseAuth.instance.currentUser!.email ?? 'No Email',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    );
                  }
                  final userData = snapshot.data!.data()!;
                  return DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.deepPurple),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userData['fullName'] ?? 'User Name',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          FirebaseAuth.instance.currentUser!.email ?? '',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.checkroom, color: Colors.white),
                title: const Text("Upper Top", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushNamed(context, '/upper_top');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.white),
                title: const Text("Lower Bottoms", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushNamed(context, '/lower_bottom');
                },
              ),
              ListTile(
                leading: const Icon(Icons.man, color: Colors.white),
                title: const Text("Update Profile", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushNamed(context, '/update_profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.man, color: Colors.white),
                title: const Text("Smart Assistant", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushNamed(context, '/face_analysis');
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: clothingStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Convert documents to a list of maps.
              final items = snapshot.data!.docs.map((doc) => doc.data()).toList();
              // Shuffle the list to display items randomly.
              items.shuffle(Random());
              return GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final data = items[index];
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              data['image'] ?? 'https://via.placeholder.com/300x400',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Text(
                            data['name'] ?? 'Item Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          data['price'].toString(),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 130,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Convert the data Map<String, dynamic> to Map<String, String>
                              final itemData = data.map((key, value) => MapEntry(key, value.toString()));
                              Provider.of<CartModel>(context, listen: false).addItem(itemData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${data['name']} added to cart"),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text("Add to Cart"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
