class SessionModel {
  final int? id;
  final String sessionCode;
  final String workerName;
  final String ageGroup;
  final String duration;
  final String rawTranscription;
  final String confirmedConcepts;
  final String triageLevel;
  final String timestamp;
  final int referralGenerated;

  SessionModel({
    this.id,
    required this.sessionCode,
    required this.workerName,
    required this.ageGroup,
    required this.duration,
    required this.rawTranscription,
    required this.confirmedConcepts,
    required this.triageLevel,
    required this.timestamp,
    this.referralGenerated = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_code': sessionCode,
      'worker_name': workerName,
      'patient_age_group': ageGroup,
      'symptom_duration': duration,
      'raw_transcription': rawTranscription,
      'confirmed_concepts': confirmedConcepts,
      'triage_level': triageLevel,
      'timestamp': timestamp,
      'referral_generated': referralGenerated,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as int?,
      sessionCode: map['session_code'] as String,
      workerName: map['worker_name'] as String? ?? '',
      ageGroup: map['patient_age_group'] as String? ?? '',
      duration: map['symptom_duration'] as String? ?? '',
      rawTranscription: map['raw_transcription'] as String? ?? '',
      confirmedConcepts: map['confirmed_concepts'] as String? ?? '[]',
      triageLevel: map['triage_level'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      referralGenerated: map['referral_generated'] as int? ?? 0,
    );
  }

  String get ageGroupHindi {
    switch (ageGroup) {
      case 'NEWBORN':
        return 'नवजात (0-28 दिन)';
      case 'CHILD':
        return 'बच्चा (1 माह - 12 वर्ष)';
      case 'ADULT':
        return 'वयस्क (13-60 वर्ष)';
      case 'ELDERLY':
        return 'बुजुर्ग (60+ वर्ष)';
      default:
        return ageGroup;
    }
  }

  String get durationHindi {
    switch (duration) {
      case 'TODAY':
        return 'आज';
      case 'TWO_THREE_DAYS':
        return '2-3 दिन';
      case 'FOUR_PLUS_DAYS':
        return '4+ दिन';
      default:
        return duration;
    }
  }

  String get triageLevelHindi {
    switch (triageLevel) {
      case 'RED':
        return '🔴 तुरंत रेफर करें';
      case 'YELLOW':
        return '🟡 आज रेफर करें';
      case 'GREEN':
        return '🟢 स्थानीय उपचार';
      default:
        return triageLevel;
    }
  }
}
