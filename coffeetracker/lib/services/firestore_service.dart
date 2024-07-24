import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<String> getDeviceUUID() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceUUID = prefs.getString('deviceUUID');

    if (deviceUUID == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId;
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Use androidId for Android devices
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? ''; // Use identifierForVendor for iOS devices
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      // Generate a UUID using the device ID as a seed
      deviceUUID = _uuid.v5(Uuid.NAMESPACE_URL, deviceId);
      await prefs.setString('deviceUUID', deviceUUID);
    }

    return deviceUUID;
  }

  Future<void> insertUserData() async {
    String deviceUUID = await getDeviceUUID();
    DocumentReference userRef = _firestore.collection('users').doc(deviceUUID);
    DocumentSnapshot doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'device_uuid': deviceUUID,
        'is_android': Platform.isAndroid,
        'is_ios': Platform.isIOS,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchData(String collection) async {
    String deviceUUID = await getDeviceUUID();
    QuerySnapshot querySnapshot = await _firestore
        .collection(collection)
        .where('device_uuid', isEqualTo: deviceUUID)
        .get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> insertData(String collection, Map<String, dynamic> data) async {
    String deviceUUID = await getDeviceUUID();
    data['device_uuid'] = deviceUUID;
    await _firestore.collection(collection).add(data);
  }

  Future<void> updateData(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteData(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<DocumentReference?> getDocumentReferenceByField(String collection, String field, dynamic value) async {
    QuerySnapshot querySnapshot = await _firestore.collection(collection).where(field, isEqualTo: value).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.reference;
    }
    return null;
  }

  Future<void> updateDataByField(String collection, String field, dynamic value, Map<String, dynamic> data) async {
    DocumentReference? docRef = await getDocumentReferenceByField(collection, field, value);
    if (docRef != null) {
      await docRef.update(data);
    } else {
      throw Exception("Document with $field = $value does not exist.");
    }
  }

  Future<void> deleteDataByField(String collection, String field, dynamic value) async {
    DocumentReference? docRef = await getDocumentReferenceByField(collection, field, value);
    if (docRef != null) {
      await docRef.delete();
    } else {
      throw Exception("Document with $field = $value does not exist.");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoffeeSizes() async {
    QuerySnapshot querySnapshot = await _firestore.collection('coffeesize').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> fetchCoffeeTypes() async {
    QuerySnapshot querySnapshot = await _firestore.collection('coffeetype').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> addCoffeeRecord(Map<String, dynamic> data) async {
    await _firestore.collection('coffeerecords').add(data);
  }

  // Add Favorite Coffee
  Future<void> addFavoriteCoffee(Map<String, dynamic> favoriteCoffee) async {
    await insertData('favorite_coffees', favoriteCoffee);
  }

  // Fetch Favorite Coffees
  Future<List<Map<String, dynamic>>> fetchFavoriteCoffees() async {
    return await fetchData('favorite_coffees');
  }

  // Delete Favorite Coffee
  Future<void> deleteFavoriteCoffee(String docId) async {
    await deleteData('favorite_coffees', docId);
  }

}
