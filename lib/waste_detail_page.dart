import 'package:flutter/material.dart';
import 'package:skripshot/models.dart';
import 'dart:async';
import 'package:skripshot/last_opened_object_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;



class ObjectDetailPage extends StatefulWidget {
  final WasteObject object;
  final String icon;

  const ObjectDetailPage({Key? key, required this.object, required this.icon})
      : super(key: key);

  @override
  State<ObjectDetailPage> createState() => _ObjectDetailPageState();
}

class _ObjectDetailPageState extends State<ObjectDetailPage> {
  Timer? _viewTimer;
  YoutubePlayerController? _youtubeController;
  int? _playingIndex; // index video yang sedang dimainkan

  @override
  void initState() {
    super.initState();

    // simpan objek setelah 10 detik
    _viewTimer = Timer(const Duration(seconds: 10), () {
      LastOpenedObjectManager().saveLastOpenedObject(widget.object);
    });
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  String? _extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.host.contains('youtube.com')) {
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }
        final segments = uri.pathSegments;
        if (segments.contains('embed') && segments.length > 1) {
          return segments[1];
        }
      }
    } catch (_) {}
    return null;
  }


  void _playVideo(String url, int index) {
    final videoId = _extractYouTubeId(url);
    if (videoId == null) return; // langsung keluar tanpa SnackBar

    setState(() {
      _youtubeController?.pause();
      _youtubeController?.dispose();

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
      _playingIndex = index;
    });
  }


  void _openYouTube(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Buka dengan browser eksternal
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<Map<String, dynamic>> _analyzeLink(String url) async {
    if (url.isEmpty) return {"type": "invalid"};

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return {"type": "invalid"};

    // Cek apakah YouTube
    final videoId = _extractYouTubeId(url);
    if (videoId != null) {
      return {
        "type": "youtube",
        "id": videoId,
        "thumbnail": "https://img.youtube.com/vi/$videoId/hqdefault.jpg",
      };
    }

    // Bukan YouTube — cek apakah linknya valid
    try {
      final response = await http.head(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return {"type": "web"};
      }
    } catch (_) {}

    return {"type": "invalid"};
  }


  @override
  Widget build(BuildContext context) {
    final object = widget.object;
    final icon = widget.icon;

    return Scaffold(
      appBar: AppBar(title: Text(object.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset(icon, width: 64, height: 64)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  object.name,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  object.categoryId=='organic'? 'Organik':
                  object.recyclable
                      ? "Dapat didaur ulang"
                      : object.hazardous
                      ? "Beracun atau Berbahaya (B3)"
                      : "Residu/Tidak dapat didaur ulang",
                  style: TextStyle(
                    color: object.recyclable
                        ? Colors.green
                        : object.hazardous
                        ? Colors.brown
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(object.description),
              const SizedBox(height: 24),
              const Divider(),
              const Text("Cara daur ulang",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Cek video ide guna ulang di bawah."),
              const Divider(),
              object.recyclingIdeas.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Belum ada ide untuk daur ulang sendiri.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
                  : ExpansionTile(
                title: const Text("Ide Guna Ulang"),
                children: object.recyclingIdeas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final idea = entry.value;
                  final url = idea['youtube_link'] ?? '';
                  final title = idea['title'] ?? 'Tanpa Judul';

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _analyzeLink(url),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ListTile(
                          title: Text("Memeriksa tautan..."),
                          leading: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      final data = snapshot.data!;
                      final type = data["type"];
                      final videoId = data["id"];
                      final thumb = data["thumbnail"];

                      if (type == "youtube") {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: thumb,
                                  width: 80,
                                  height: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(title),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _openYouTube(url),
                              ),
                              onTap: () => _playVideo(url, index),
                            ),
                            if (_playingIndex == index && _youtubeController != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: YoutubePlayer(
                                  controller: _youtubeController!,
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: Colors.redAccent,
                                ),
                              ),
                            const Divider(),
                          ],
                        );
                      } else if (type == "web") {
                        return Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.language, color: Colors.blueAccent),
                              title: Text(title),
                              subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_browser),
                                onPressed: () => _openYouTube(url),
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.error_outline, color: Colors.grey),
                              title: Text(title),
                              subtitle: const Text("⚠️ Link rusak atau tidak ditemukan"),
                            ),
                            const Divider(),
                          ],
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

