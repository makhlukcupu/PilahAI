import 'package:flutter/material.dart';
import 'package:skripshot/models.dart';
import 'dart:async';
import 'package:skripshot/last_opened_object_manager.dart';


class ObjectDetailPage extends StatefulWidget {
  final WasteObject object;
  final String icon;

  const ObjectDetailPage({Key? key, required this.object, required this.icon}) : super(key: key);

  @override
  State<ObjectDetailPage> createState() => _ObjectDetailPageState();
}

// class ObjectDetailPage extends StatelessWidget {
//   //final String objectName;
//   final WasteObject object;
//   final String icon;
//   //late final object = WasteRepository.objects.firstWhere((o) => o.name == objectName);
//   ObjectDetailPage({Key? key, required this.object, required this.icon}) : super(key: key);

class _ObjectDetailPageState extends State<ObjectDetailPage> {
  Timer? _viewTimer;


  @override
  void initState() {
    super.initState();

    // Start a 10-second timer to save this object as recently opened
    _viewTimer = Timer(const Duration(seconds: 10), () {
      LastOpenedObjectManager().saveLastOpenedObject(widget.object);
    });
  }

  @override
  void dispose() {
    // Cancel timer if user leaves before 10 seconds
    _viewTimer?.cancel();
    super.dispose();
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
              Center(child:Image.asset(icon, width: 48, height: 48) ,),
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
                children: object.recyclingIdeas.map((idea) {
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


