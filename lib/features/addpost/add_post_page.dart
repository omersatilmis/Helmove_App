import 'package:flutter/material.dart';

class AddPostPage extends StatelessWidget {
  const AddPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paylaşım Yap")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Fotoğraf/Video Yükleme Alanı"),
          ],
        ),
      ),
    );
  }
}