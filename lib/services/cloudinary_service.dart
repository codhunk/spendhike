import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Central Cloudinary Service for image capture and cloud upload.
class CloudinaryService {
  static const String cloudName = 'dcbmy6vtg';
  static const String apiKey = '286528494914523';
  static const String apiSecret = 'DJhArCgx_4E7XeSAS6VL3clbuJI';
  static const String unsignedUploadPreset = 'spendhike_preset';

  static final ImagePicker _picker = ImagePicker();

  /// Capture image using device camera
  static Future<XFile?> pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      debugPrint('[CloudinaryService] Camera pick error: $e');
      return null;
    }
  }

  /// Pick image from device gallery
  static Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('[CloudinaryService] Gallery pick error: $e');
      return null;
    }
  }

  /// Upload file to Cloudinary (using Backend Upload API or direct Cloudinary REST endpoint)
  static Future<String?> uploadImage(XFile file, {String folder = 'spendhike_uploads'}) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // 1. Try uploading through SpendHike backend API
      final backendUploadUrl = '${ApiConfig.baseUrl}/upload/image';
      final token = ApiService.authToken;

      final res = await http.post(
        Uri.parse(backendUploadUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image': base64Image,
          'folder': folder,
        }),
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['url'] != null) {
          return data['url'] as String;
        }
      }

      // 2. Direct Cloudinary REST API fallback upload
      return await _directCloudinaryUpload(bytes, folder: folder);
    } catch (e) {
      debugPrint('[CloudinaryService] Upload exception: $e');
      // Direct Cloudinary fallback
      try {
        final bytes = await file.readAsBytes();
        return await _directCloudinaryUpload(bytes, folder: folder);
      } catch (err) {
        return null;
      }
    }
  }

  /// Direct Cloudinary Unsigned/API upload fallback
  static Future<String?> _directCloudinaryUpload(Uint8List bytes, {required String folder}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final req = http.MultipartRequest('POST', uri);
    req.fields['upload_preset'] = unsignedUploadPreset;
    req.fields['folder'] = folder;
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'));

    final streamedRes = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['secure_url'] as String?;
    }
    return null;
  }
}
