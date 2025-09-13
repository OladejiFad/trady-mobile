import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../global/auth_data.dart';
import '../models/property_model.dart';

class PropertyService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/properties';

  Future<List<Property>> fetchPropertiesByLandlord(String landlordId) async {
    final uri = Uri.parse('$baseUrl/landlord/$landlordId');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${AuthData.token}',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch landlord properties: ${response.statusCode}');
    }
  }

  Future<List<Property>> fetchApprovedProperties() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch approved properties: ${response.statusCode}');
    }
  }

  Future<void> createProperty({
    required String landlordId,
    required String title,
    String? description,
    required String propertyType,
    required String transactionType,
    required double price,
    List<XFile>? images,
    List<XFile>? documents,
    XFile? video,
    Map<String, dynamic>? locationDetails,
    List<String>? amenities,
    Map<String, dynamic>? availability,
  }) async {
    final uri = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${AuthData.token}'
      ..fields['landlordId'] = landlordId
      ..fields['title'] = title
      ..fields['propertyType'] = propertyType
      ..fields['transactionType'] = transactionType
      ..fields['price'] = price.toString();

    if (description?.isNotEmpty ?? false) request.fields['description'] = description!;
    if (locationDetails != null) request.fields['locationDetails'] = jsonEncode(locationDetails);
    if (amenities != null) request.fields['amenities'] = jsonEncode(amenities);
    if (availability != null) request.fields['availability'] = jsonEncode(availability);

    if (images != null) {
      for (var img in images) {
        if (kIsWeb) {
          var bytes = await img.readAsBytes();
          var mime = lookupMimeType(img.name);
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: img.name,
            contentType: mime != null ? MediaType.parse(mime) : null,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('images', img.path));
        }
      }
    }

    if (documents != null) {
      for (var doc in documents) {
        if (kIsWeb) {
          var bytes = await doc.readAsBytes();
          var mime = lookupMimeType(doc.name);
          request.files.add(http.MultipartFile.fromBytes(
            'documents',
            bytes,
            filename: doc.name,
            contentType: mime != null ? MediaType.parse(mime) : null,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('documents', doc.path));
        }
      }
    }

    if (video != null) {
      if (kIsWeb) {
        var bytes = await video.readAsBytes();
        var mime = lookupMimeType(video.name);
        request.files.add(http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: video.name,
          contentType: mime != null ? MediaType.parse(mime) : null,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('video', video.path));
      }
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Property upload successful: ${responseBody.body}');
    } else {
      throw Exception('❌ Create property failed: ${response.statusCode} - ${responseBody.body}');
    }
  }

  Future<void> updateProperty({
    required String propertyId,
    String? title,
    String? description,
    String? propertyType,
    String? transactionType,
    double? price,
    List<XFile>? newImages,
    List<XFile>? newDocuments,
    XFile? newVideo,
    Map<String, dynamic>? locationDetails,
    List<String>? amenities,
    Map<String, dynamic>? availability,
  }) async {
    final uri = Uri.parse('$baseUrl/$propertyId');
    var request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer ${AuthData.token}';

    if (title?.isNotEmpty ?? false) request.fields['title'] = title!;
    if (description?.isNotEmpty ?? false) request.fields['description'] = description!;
    if (propertyType?.isNotEmpty ?? false) request.fields['propertyType'] = propertyType!;
    if (transactionType?.isNotEmpty ?? false) request.fields['transactionType'] = transactionType!;
    if (price != null) request.fields['price'] = price.toString();
    if (locationDetails != null) request.fields['locationDetails'] = jsonEncode(locationDetails);
    if (amenities != null) request.fields['amenities'] = jsonEncode(amenities);
    if (availability != null) request.fields['availability'] = jsonEncode(availability);

    if (newImages != null) {
      for (var img in newImages) {
        if (kIsWeb) {
          var bytes = await img.readAsBytes();
          var mime = lookupMimeType(img.name);
          request.files.add(http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: img.name,
            contentType: mime != null ? MediaType.parse(mime) : null,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('images', img.path));
        }
      }
    }

    if (newDocuments != null) {
      for (var doc in newDocuments) {
        if (kIsWeb) {
          var bytes = await doc.readAsBytes();
          var mime = lookupMimeType(doc.name);
          request.files.add(http.MultipartFile.fromBytes(
            'documents',
            bytes,
            filename: doc.name,
            contentType: mime != null ? MediaType.parse(mime) : null,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('documents', doc.path));
        }
      }
    }

    if (newVideo != null) {
      if (kIsWeb) {
        var bytes = await newVideo.readAsBytes();
        var mime = lookupMimeType(newVideo.name);
        request.files.add(http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: newVideo.name,
          contentType: mime != null ? MediaType.parse(mime) : null,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('video', newVideo.path));
      }
    }

    final response = await request.send();
    final body = await http.Response.fromStream(response);

    if (response.statusCode != 200) {
      throw Exception('Update property failed: ${response.statusCode} - ${body.body}');
    }
  }

  /// ✅ Now static: can be used as PropertyService.fetchPropertyById(id)
  static Future<Property> fetchPropertyById(String propertyId) async {
    final uri = Uri.parse('$baseUrl/$propertyId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Property.fromJson(json);
    } else {
      throw Exception('Failed to fetch property: ${response.statusCode}');
    }
  }
}
