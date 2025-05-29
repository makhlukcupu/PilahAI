import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentang Aplikasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi ini merupakan aplikasi deteksi dan edukasi sampah yang dirancang '
                  'untuk membantu pengguna mengenali jenis sampah serta memberikan informasi bagaimana untuk memilah sampah tersebut',
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplikasi ini dikembangkan sebagai bagian dari tugas akhir (skripsi) pengembang.'
            ),
            const SizedBox(height: 8),
            const Text('Fitur utama:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Deteksi beberapa sampah menggunakan kamera.'),
                  Text('• Pencarian manual objek sampah yang ingin dipilah.'),
                  Text('• Deskripsi dan informasi tentang cara menangani memilah tiap objek sampah.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi ini gratis dan dapat digunakan oleh siapa saja tanpa koneksi internet.',
            ),

            const SizedBox(height: 16),
            const Text(
              'Kekurangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deteksi objek sampah saat ini masih terbatas pada beberapa jenis saja, '
                  'karena keterbatasan data foto sampah dan juga aplikasi masih dalam tahap pengembangan.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Informasi tentang sampah belum teroptimisasi, bisa dibilang masih dummy. Dibutuhkan orang yang memiliki ilmu tentang sampah untuk mengisi informasi dengan akurat, bisa hubungi WA: 082321613506',
            ),
            const SizedBox(height: 16),
            const Text(
              'Dukungan dan Donasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Jika Anda ingin ikut berkontribusi pengembangan aplikasi ini, Anda dapat berdonasi melalui link saweria berikut:'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                const url = 'https://saweria.co/namaanda'; // ganti dengan link asli
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              child: const Text(
                'https://saweria.co/makhlukcupu',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Atau ikut berkontribusi dengan mengunggah foto sampah beserta nama dan kategori objek.\n'
                  '(Fitur ini masih dalam tahap pengembangan.)',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
