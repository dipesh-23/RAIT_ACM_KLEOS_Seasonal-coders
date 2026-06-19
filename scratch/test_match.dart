import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() async {
  final file = File('d:/RAIT_HACK/frontend/assets/anchors/clinical_anchors.json');
  final rawJson = await file.readAsString();
  final data = jsonDecode(rawJson) as Map<String, dynamic>;

  final List<List<String>> hindiKeywords = [];
  final anchorsList = data['anchors'] as List<dynamic>;
  for (final entry in anchorsList) {
    final concept = entry as Map<String, dynamic>;
    final rawKeywords = concept['hindi_keywords'];
    if (rawKeywords is List) {
      hindiKeywords.add(rawKeywords.cast<String>());
    } else {
      hindiKeywords.add([]);
    }
  }

  String transcript = 'सांस लेने में तकलीफ';
  
  bool isHindi = transcript.runes.any((r) => r >= 0x0900 && r <= 0x097F);
  print('isHindi: $isHindi');

  for (int i = 0; i < anchorsList.length; i++) {
    final kwList = hindiKeywords[i];
    if (kwList.isEmpty) continue;
    
    int hits = 0;
    for (final kw in kwList) {
      if (transcript.contains(kw)) hits++;
    }
    if (hits > 0) {
      double score = (0.60 + 0.05 * (hits - 1)).clamp(0.0, 0.95);
      print('Match for anchor ${anchorsList[i]['key']}: hits=$hits, score=$score');
    }
  }
}
