import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/glow_up_entry_entity.dart';

class GlowUpLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _key = 'GLOW_UP_HISTORY';

  GlowUpLocalDataSource({required this.sharedPreferences});

  Future<void> saveEntry(GlowUpEntryEntity entry) async {
    final existing = await getAllEntries();
    final updated = [entry, ...existing];
    final encoded = jsonEncode(updated.map(_toJson).toList());
    await sharedPreferences.setString(_key, encoded);
  }

  Future<List<GlowUpEntryEntity>> getAllEntries() async {
    final raw = sharedPreferences.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearAll() async {
    await sharedPreferences.remove(_key);
  }

  Map<String, dynamic> _toJson(GlowUpEntryEntity e) => {
        'id': e.id,
        'imagePath': e.imagePath,
        'overallScore': e.overallScore,
        'eyeScore': e.eyeScore,
        'noseScore': e.noseScore,
        'mouthScore': e.mouthScore,
        'timestamp': e.timestamp.toIso8601String(),
      };

  GlowUpEntryEntity _fromJson(Map<String, dynamic> json) => GlowUpEntryEntity(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        overallScore: (json['overallScore'] as num).toDouble(),
        eyeScore: (json['eyeScore'] as num).toDouble(),
        noseScore: (json['noseScore'] as num).toDouble(),
        mouthScore: (json['mouthScore'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
