import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skripshot/models.dart';

class ObjectDetailPage extends StatelessWidget {
  final RecyclableObject object;

  const ObjectDetailPage({Key? key, required this.object}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(object.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child:Image.asset(object.icon, width: 48, height: 48) ,),
              SizedBox(height: 8),
              Center(child: Text(object.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              Center(child: Text(
                object.recyclable ? "Dapat didaur ulang" : "Tidak dapat didaur ulang",
                style: TextStyle(color: object.recyclable ? Colors.green : Colors.red),
              ),),
              SizedBox(height: 16),
              Text(object.description),
              SizedBox(height: 24),
              Divider(),
              Text("Cara daur ulang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Cek video ide guna ulang di bawah."),
              Divider(),
              ExpansionTile(
                title: Text("Ide Guna Ulang"),
                children: object.ideas.map((idea) {
                  return ListTile(
                    leading: Text("[Thumbnail]"), // use CachedNetworkImage in actual app
                    title: Text(idea.title),
                    onTap: () {
                      // Optionally: open URL or show preview
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


// class ObjectDetailPage extends StatefulWidget {
//   @override
//   _ObjectDetailPageState createState() => _ObjectDetailPageState();
// }
//
// class _ObjectDetailPageState extends State<ObjectDetailPage> {
//   final RecyclableObject object;
//   const ObjectDetailPage({required this.object});
//
//   bool showIdeas = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final ideas = object['ideas'] ?? [];
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Optional: open camera or rescan
//         },
//         backgroundColor: Colors.green,
//         child: Icon(Icons.camera_alt),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Back Button
//                 IconButton(
//                   icon: Icon(Icons.arrow_back, color: Colors.green[800]),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//
//                 SizedBox(height: 8),
//
//                 // Icon
//                 Center(
//                   child: Image.asset(
//                     objectData['icon'],
//                     width: 80,
//                     height: 80,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//
//                 // Name
//                 Center(
//                   child: Text(
//                     objectData['name'],
//                     style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//
//                 // Recyclability Status
//                 Center(
//                   child: Text(
//                     objectData['recyclable']
//                         ? "♻️ Dapat Didaur Ulang"
//                         : "🚫 Tidak Didaur Ulang",
//                     style: TextStyle(
//                       color: objectData['recyclable']
//                           ? Colors.green
//                           : Colors.red,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//
//                 SizedBox(height: 24),
//
//                 // Description
//                 Text(
//                   objectData['description'],
//                   style: TextStyle(fontSize: 16),
//                 ),
//
//                 // Divider
//                 if (ideas.isNotEmpty) ...[
//                   Divider(height: 32, color: Colors.grey[400]),
//
//                   // Dropdown Header
//                   GestureDetector(
//                     onTap: () => setState(() => showIdeas = !showIdeas),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Ide Guna Ulang",
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Icon(
//                           showIdeas
//                               ? Icons.expand_less
//                               : Icons.expand_more,
//                           size: 28,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 12),
//
//                   // Dropdown Content
//                   if (showIdeas)
//                     Column(
//                       children: ideas.map<Widget>((idea) {
//                         final videoId = idea['youtubeId'];
//                         final thumbnailUrl =
//                             'https://img.youtube.com/vi/$videoId/0.jpg';
//                         return Card(
//                           margin: EdgeInsets.symmetric(vertical: 8),
//                           child: ListTile(
//                             leading: CachedNetworkImage(
//                               imageUrl: thumbnailUrl,
//                               placeholder: (context, url) => Container(
//                                 width: 64,
//                                 height: 48,
//                                 alignment: Alignment.center,
//                                 child: CircularProgressIndicator(strokeWidth: 2),
//                               ),
//                               errorWidget: (context, url, error) => Container(
//                                 width: 64,
//                                 height: 48,
//                                 color: Colors.grey[300],
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   "No Image",
//                                   style: TextStyle(fontSize: 10),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                               width: 64,
//                               height: 48,
//                               fit: BoxFit.cover,
//                             ),
//                             title: Text(idea['title']),
//                             onTap: () {
//                               // Optional: open video link or offline idea page
//                             },
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
