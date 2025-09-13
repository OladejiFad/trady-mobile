import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../models/product_model.dart';
import '../models/seller_model.dart';
import '../global/auth_data.dart';

class ProductService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/products';

  static Future<List<Product>> fetchSellerProducts() async {
    final uri = Uri.parse('$baseUrl/seller');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer ${AuthData.token}',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch seller products: ${response.statusCode}');
    }
  }

  static Future<List<Product>> fetchFilteredProducts({
    String? search,
    String? category,
  }) async {
    final queryParameters = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParameters['category'] = category;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch products: ${response.statusCode}');
    }
  }

  static Future<Product> fetchProductById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load product');
    }
  }

  static Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    required List<XFile> images,
    required bool isBargainable,
    String? marketSection,
    List<String> sizes = const [],
    List<String> colors = const [],
    double discount = 0,
  }) async {
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${AuthData.token}'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['category'] = category
      ..fields['price'] = price.toString()
      ..fields['stock'] = stock.toString()
      ..fields['isBargainable'] = isBargainable.toString()
      ..fields['discount'] = discount.toString();

    if (marketSection != null) {
      request.fields['marketSection'] = marketSection;
    }
    if (sizes.isNotEmpty) {
      request.fields['sizes'] = jsonEncode(sizes);
    }
    if (colors.isNotEmpty) {
      request.fields['colors'] = jsonEncode(colors);
    }

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

    final response = await request.send();
    if (response.statusCode != 201 && response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Create failed: ${response.statusCode} - $body');
    }
  }

  static Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    String? category,
    double? price,
    int? stock,
    List<XFile>? newImages,
    double? ratingsAverage,
    int? ratingsQuantity,
    bool? isBargainable,
    String? marketSection,
    List<String> sizes = const [],
    List<String> colors = const [],
    double? discount,
  }) async {
    final uri = Uri.parse('$baseUrl/$productId');
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer ${AuthData.token}';

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (category != null) request.fields['category'] = category;
    if (price != null) request.fields['price'] = price.toString();
    if (stock != null) request.fields['stock'] = stock.toString();
    if (ratingsAverage != null) request.fields['ratingsAverage'] = ratingsAverage.toString();
    if (ratingsQuantity != null) request.fields['ratingsQuantity'] = ratingsQuantity.toString();
    if (isBargainable != null) request.fields['isBargainable'] = isBargainable.toString();
    if (marketSection != null) request.fields['marketSection'] = marketSection;
    if (sizes.isNotEmpty) request.fields['sizes'] = jsonEncode(sizes);
    if (colors.isNotEmpty) request.fields['colors'] = jsonEncode(colors);
    if (discount != null) request.fields['discount'] = discount.toString();

    if (newImages != null && newImages.isNotEmpty) {
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

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Update failed: ${response.statusCode} - $body');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    final uri = Uri.parse('$baseUrl/$productId');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${AuthData.token}',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Product>> fetchProductsBySeller(String sellerId) async {
    final uri = Uri.parse('$baseUrl/seller/$sellerId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch products for seller: ${response.statusCode}');
    }
  }

  static Future<List<String>> fetchTopSellers() async {
    final uri = Uri.parse('http://172.20.10.2:5000/api/top-sellers');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> topStores = data['topStores'];
      return topStores.map<String>((store) => store['sellerId'].toString()).toList();
    } else {
      throw Exception('Failed to fetch top sellers: ${response.statusCode}');
    }
  }

  // ✅ Fetch current seller profile using token
 static Future<SellerModel> fetchSellerProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
  Uri.parse('http://172.20.10.2:5000/api/auth/profile'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);


  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return SellerModel.fromJson(data);
  } else {
    throw Exception('Failed to fetch seller profile');
  }
}

// ✅ Fetch the latest products by seller (limit = 3)
static Future<List<Product>> fetchLatestProductsBySeller(String sellerId) async {
  final uri = Uri.parse('$baseUrl/seller/$sellerId?limit=3');

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch latest products: ${response.statusCode}');
  }
}


}
