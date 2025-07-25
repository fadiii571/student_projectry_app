import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<void> Addemployee({
  required String name,
  required String number,
  required String state,
  required String salary,
  required String section,
  required String profileimageUrl,
  required String imageUrl,
  required String location,
  required double latitude,
  required double longitude,
  required BuildContext context,
}) async {
  try { 


    await FirebaseFirestore.instance.collection("Employees").add({
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
      "image": imageUrl,
      "profileimage": profileimageUrl,
      "location": location,
      "latitude": latitude, 
      "longitude": longitude,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Employee added successfully",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
Future<String?> uploadToCloudinary() async {
  final cloudName = 'dzfr5nkxt';
  final uploadPreset = 'employee_images';
  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  Uint8List? imageBytes;
  String fileName;

  if (kIsWeb) {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (result == null || result.files.single.bytes == null) return null;
    imageBytes = result.files.single.bytes!;
    fileName = result.files.single.name;
  } else {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    imageBytes = await pickedFile.readAsBytes();
    fileName = pickedFile.name;
  }

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final data = json.decode(responseBody);
    return data['secure_url'];
  } else {
    print("Upload failed: ${response.reasonPhrase}");
    return null;
  }
}

 Stream<QuerySnapshot> getEmployees({String? section}) {
    if (section == null) {
      return FirebaseFirestore.instance.collection("Employees").snapshots();
    } else {
      return FirebaseFirestore.instance.collection("Employees").where("section", isEqualTo: section).snapshots();
    }
  }
Future<void> deletemp(String id)async{
  await FirebaseFirestore.instance.collection("Employees").doc(id).delete();
}
Future<void> updateemployee({
 required String id,
  required String name,
  required String number,
  required String state,
  required String salary,
  required String section,
  required String location,
  required double latitude,
  required double longitude,
  required bool isActive,
  required BuildContext context,
}) async {
  try {
    await FirebaseFirestore.instance.collection("Employees").doc(id).update({
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
      "location": location,
      "latitude": latitude, 
      "longitude": longitude,
      'status': isActive,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Employee data updated successfully",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> markAttendanceByAdmin({
  required String employeeId,
  required String name,
  required String status,
  required String date, // in yyyy-MM-dd format
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(date)
        .collection('records')
        .doc(employeeId)
        .set({
      'employeeId': employeeId,
      'name': name,
      'status': status,
      'markedBy': 'admin',
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print("Error marking attendance: $e");
  }
}

Future<List<Map<String, dynamic>>> getAttendanceHistory({
  required String employeeId,
  String? date, 
}) async {
  final attendanceRef = FirebaseFirestore.instance.collection('attendance');

  List<Map<String, dynamic>> history = [];

  if (date != null) {
    final doc = await attendanceRef.doc(date).collection('records').doc(employeeId).get();
    if (doc.exists) {
      history.add(doc.data()!..['date'] = date);
    }
  } else {
    final datesSnapshot = await attendanceRef.get();
    for (final dateDoc in datesSnapshot.docs) {
      final recordSnapshot = await dateDoc.reference.collection('records').doc(employeeId).get();
      if (recordSnapshot.exists) {
        history.add(recordSnapshot.data()!..['date'] = dateDoc.id);
      }
    }
  }

  return history;
}