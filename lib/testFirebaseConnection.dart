import 'package:cloud_firestore/cloud_firestore.dart';

void testFirebase() {
  FirebaseFirestore.instance.collection("test").add({
    "msg": "Hello Firebase",
    "time": DateTime.now(),
  });
}
