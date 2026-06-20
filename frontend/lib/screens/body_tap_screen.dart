import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/detected_concept.dart';
import '../providers/triage_provider.dart';
import 'confirmation_screen.dart';

class BodyRegionSymptom {
  final String conceptKey;
  final String englishLabel;
  final String hindiLabel;
  final String hindiQuestion;
  final String category;
  final int weight;

  const BodyRegionSymptom({
    required this.conceptKey,
    required this.englishLabel,
    required this.hindiLabel,
    required this.hindiQuestion,
    required this.category,
    required this.weight,
  });
}

class BodyTapScreen extends StatefulWidget {
  const BodyTapScreen({super.key});
  @override
  State<BodyTapScreen> createState() => _BodyTapScreenState();
}

class _BodyTapScreenState extends State<BodyTapScreen> {
  Set<String> selectedConceptKeys = {};
  String? activeRegion;

  static const Map<String, List<BodyRegionSymptom>> regionSymptoms = {
    'head': [
      BodyRegionSymptom(conceptKey: 'unconscious', englishLabel: 'Unconscious / Unresponsive', hindiLabel: 'बेहोश / बेसुध', hindiQuestion: 'क्या मरीज बेहोश है या जवाब नहीं दे रहा?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'seizure', englishLabel: 'Seizure / Fits', hindiLabel: 'दौरा / मिर्गी', hindiQuestion: 'क्या मरीज को दौरा पड़ा?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'stroke_signs', englishLabel: 'Stroke Signs (Face Drooping)', hindiLabel: 'चेहरा झुकना / बोलने में दिक्कत', hindiQuestion: 'क्या मरीज का चेहरा एक तरफ झुक गया है या बोलने में अचानक दिक्कत हो रही है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'mental_health_crisis', englishLabel: 'Mental Health Crisis', hindiLabel: 'अजीब व्यवहार / आक्रामक', hindiQuestion: 'क्या मरीज बहुत आक्रामक है या अजीब व्यवहार कर रहा है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'severe_headache', englishLabel: 'Severe Headache', hindiLabel: 'तेज सिरदर्द', hindiQuestion: 'क्या मरीज के सिर में बहुत तेज दर्द है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'eye_pain_redness', englishLabel: 'Eye Pain / Redness', hindiLabel: 'आंख में दर्द / लाल', hindiQuestion: 'क्या मरीज की आंख में बहुत तेज दर्द है या अचानक दिखना बंद हो गया?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'ear_pain_discharge', englishLabel: 'Ear Pain / Discharge', hindiLabel: 'कान दर्द / मवाद', hindiQuestion: 'क्या मरीज के कान में बहुत दर्द है या कान से पानी आ रहा है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'mild_headache', englishLabel: 'Mild Headache', hindiLabel: 'हल्का सिरदर्द', hindiQuestion: 'क्या मरीज को हल्का सिरदर्द है?', category: 'GREEN', weight: 1),
    ],
    'chest': [
      BodyRegionSymptom(conceptKey: 'breathing_difficulty', englishLabel: 'Breathing Difficulty', hindiLabel: 'सांस लेने में तकलीफ', hindiQuestion: 'क्या मरीज को सांस लेने में तकलीफ है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'choking_foreign_body', englishLabel: 'Choking / Blocked Airway', hindiLabel: 'गला घुटना', hindiQuestion: 'क्या मरीज के गले में कुछ फंसा है या वो सांस नहीं ले पा रहा?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'chest_pain', englishLabel: 'Chest Pain', hindiLabel: 'सीने में दर्द', hindiQuestion: 'क्या मरीज के सीने में दर्द है?', category: 'RED', weight: 9),
      BodyRegionSymptom(conceptKey: 'hypertension_crisis', englishLabel: 'Hypertension Crisis', hindiLabel: 'हाई ब्लड प्रेशर', hindiQuestion: 'क्या मरीज का ब्लड प्रेशर बहुत ज्यादा है या सिर में बहुत तेज दर्द के साथ धुंधला दिख रहा है?', category: 'RED', weight: 9),
      BodyRegionSymptom(conceptKey: 'chest_infection_wheeze', englishLabel: 'Chest Infection / Wheezing', hindiLabel: 'घरघराहट', hindiQuestion: 'क्या मरीज की सांस में घरघराहट की आवाज़ आ रही है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'common_cold', englishLabel: 'Common Cold / Cough', hindiLabel: 'सर्दी जुकाम', hindiQuestion: 'क्या मरीज को सर्दी जुकाम है?', category: 'GREEN', weight: 1),
    ],
    'stomach': [
      BodyRegionSymptom(conceptKey: 'labor_complication', englishLabel: 'Labor / Delivery Complication', hindiLabel: 'प्रसव में जटिलता', hindiQuestion: 'क्या प्रसव में कोई समस्या आ रही है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'poisoning_overdose', englishLabel: 'Poisoning / Overdose', hindiLabel: 'जहर / दवा का ओवरडोज', hindiQuestion: 'क्या मरीज ने कोई जहर या बहुत ज्यादा दवा खा ली है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'not_eating_drinking', englishLabel: 'Not Eating / Drinking', hindiLabel: 'खाना-पीना बंद', hindiQuestion: 'क्या मरीज ने खाना पीना बंद कर दिया है?', category: 'RED', weight: 8),
      BodyRegionSymptom(conceptKey: 'pregnancy_concern', englishLabel: 'Pregnancy Concern', hindiLabel: 'गर्भावस्था समस्या', hindiQuestion: 'क्या गर्भवती महिला को कोई परेशानी है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'postpartum_concern', englishLabel: 'Postpartum Concern', hindiLabel: 'डिलीवरी के बाद समस्या', hindiQuestion: 'क्या मरीज ने हाल ही में बच्चा जना है और उसे बुखार या खून आ रहा है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'repeated_vomiting', englishLabel: 'Repeated Vomiting', hindiLabel: 'बार-बार उल्टी', hindiQuestion: 'क्या मरीज को बार-बार उल्टी हो रही है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'severe_diarrhea', englishLabel: 'Severe Diarrhea', hindiLabel: 'गंभीर दस्त', hindiQuestion: 'क्या मरीज को बहुत ज्यादा दस्त हो रहे हैं?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'urinary_problem', englishLabel: 'Urinary Problem', hindiLabel: 'पेशाब में दिक्कत / जलन', hindiQuestion: 'क्या मरीज को पेशाब करने में दर्द या जलन हो रही है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'minor_stomach_ache', englishLabel: 'Minor Stomach Ache', hindiLabel: 'हल्का पेट दर्द', hindiQuestion: 'क्या मरीज के पेट में हल्का दर्द है?', category: 'GREEN', weight: 1),
      BodyRegionSymptom(conceptKey: 'constipation', englishLabel: 'Constipation', hindiLabel: 'कब्ज़', hindiQuestion: 'क्या मरीज को कब्ज़ है या मल त्यागने में दिक्कत है?', category: 'GREEN', weight: 1),
      BodyRegionSymptom(conceptKey: 'worm_infestation', englishLabel: 'Worm Infestation', hindiLabel: 'पेट में कीड़े', hindiQuestion: 'क्या बच्चे के पेट में कीड़े हैं?', category: 'GREEN', weight: 1),
    ],
    'arms_hands': [
      BodyRegionSymptom(conceptKey: 'trauma_accident', englishLabel: 'Trauma / Accident (Arms)', hindiLabel: 'गंभीर चोट (हाथ)', hindiQuestion: 'क्या मरीज को कोई गंभीर चोट या दुर्घटना हुई है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'severe_bleeding', englishLabel: 'Severe Bleeding', hindiLabel: 'बहुत खून बहना', hindiQuestion: 'क्या मरीज को बहुत ज्यादा खून आ रहा है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'snakebite_animal_bite', englishLabel: 'Snakebite / Animal Bite', hindiLabel: 'सांप / जानवर का काटना', hindiQuestion: 'क्या मरीज को सांप या किसी जहरीले जानवर ने काटा है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'minor_cut_wound', englishLabel: 'Minor Cut / Wound', hindiLabel: 'छोटी कट या खरोंच', hindiQuestion: 'क्या मरीज को छोटी कट या खरोंच लगी है?', category: 'GREEN', weight: 1),
    ],
    'legs_feet': [
      BodyRegionSymptom(conceptKey: 'trauma_accident', englishLabel: 'Trauma / Accident (Legs)', hindiLabel: 'गंभीर चोट (पैर)', hindiQuestion: 'क्या मरीज को कोई गंभीर चोट या दुर्घटना हुई है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'dog_bite_wound', englishLabel: 'Dog Bite / Animal Wound', hindiLabel: 'कुत्ते का काटना', hindiQuestion: 'क्या मरीज को कुत्ते या किसी जानवर ने काटा है या घाव में पस है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'body_swelling', englishLabel: 'Leg / Feet Swelling', hindiLabel: 'पैरों में सूजन', hindiQuestion: 'क्या मरीज के पैरों में सूजन है?', category: 'YELLOW', weight: 5),
    ],
    'skin_whole_body': [
      BodyRegionSymptom(conceptKey: 'newborn_emergency', englishLabel: 'Newborn Emergency', hindiLabel: 'नवजात शिशु आपातकाल', hindiQuestion: 'क्या नवजात शिशु को कोई गंभीर समस्या है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'severe_allergic_reaction', englishLabel: 'Severe Allergic Reaction', hindiLabel: 'गंभीर एलर्जी', hindiQuestion: 'क्या मरीज के चेहरे या गले में अचानक सूजन आ गई है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'fever_with_seizure', englishLabel: 'Fever with Seizure', hindiLabel: 'बुखार के साथ दौरा', hindiQuestion: 'क्या बुखार के साथ दौरा या कंपकंपी आई है?', category: 'RED', weight: 10),
      BodyRegionSymptom(conceptKey: 'severe_dehydration', englishLabel: 'Severe Dehydration', hindiLabel: 'गंभीर पानी की कमी', hindiQuestion: 'क्या मरीज की आंखें धंसी हुई हैं या मुंह बिल्कुल सूखा है?', category: 'RED', weight: 9),
      BodyRegionSymptom(conceptKey: 'severe_burn', englishLabel: 'Severe Burn', hindiLabel: 'गंभीर जलन', hindiQuestion: 'क्या मरीज को गंभीर जलन या आग से बड़ी चोट लगी है?', category: 'RED', weight: 9),
      BodyRegionSymptom(conceptKey: 'diabetic_emergency', englishLabel: 'Diabetic Emergency', hindiLabel: 'डायबिटिक इमरजेंसी', hindiQuestion: 'क्या मरीज शुगर का मरीज है और बेहोश या कांप रहा है?', category: 'RED', weight: 9),
      BodyRegionSymptom(conceptKey: 'high_fever_prolonged', englishLabel: 'Prolonged High Fever', hindiLabel: 'कई दिनों से तेज बुखार', hindiQuestion: 'क्या मरीज को कई दिनों से तेज बुखार है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'fever_high', englishLabel: 'High Fever', hindiLabel: 'बहुत तेज बुखार', hindiQuestion: 'क्या मरीज को बहुत तेज बुखार है जो कम नहीं हो रहा?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'child_lethargic', englishLabel: 'Lethargic Child', hindiLabel: 'बच्चा सुस्त है', hindiQuestion: 'क्या बच्चा बहुत सुस्त और कमज़ोर है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'malnutrition', englishLabel: 'Severe Malnutrition', hindiLabel: 'कुपोषण / बहुत कमज़ोर', hindiQuestion: 'क्या बच्चा बहुत कमज़ोर है और उसकी हड्डियां दिख रही हैं?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'jaundice', englishLabel: 'Jaundice / Yellowing', hindiLabel: 'पीलिया', hindiQuestion: 'क्या मरीज की आंखें या त्वचा पीली दिख रही है?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'rash_with_fever', englishLabel: 'Rash with Fever', hindiLabel: 'बुखार के साथ दाने', hindiQuestion: 'क्या मरीज को बुखार के साथ शरीर पर दाने या चकत्ते हैं?', category: 'YELLOW', weight: 6),
      BodyRegionSymptom(conceptKey: 'body_swelling', englishLabel: 'Body Swelling', hindiLabel: 'शरीर में सूजन', hindiQuestion: 'क्या मरीज के शरीर में सूजन है?', category: 'YELLOW', weight: 5),
      BodyRegionSymptom(conceptKey: 'mild_fever', englishLabel: 'Mild Fever', hindiLabel: 'हल्का बुखार', hindiQuestion: 'क्या मरीज को हल्का बुखार है?', category: 'GREEN', weight: 2),
      BodyRegionSymptom(conceptKey: 'skin_allergy_itching', englishLabel: 'Skin Allergy / Itching', hindiLabel: 'हल्की एलर्जी / खुजली', hindiQuestion: 'क्या मरीज की त्वचा में हल्की खुजली या एलर्जी है?', category: 'GREEN', weight: 2),
      BodyRegionSymptom(conceptKey: 'minor_body_ache', englishLabel: 'Minor Body Ache', hindiLabel: 'हल्का बदन दर्द', hindiQuestion: 'क्या मरीज के शरीर में हल्का दर्द है?', category: 'GREEN', weight: 1),
    ],
  };

  void _showSymptomSheet(BuildContext context, String region) {
    setState(() => activeRegion = region);
    final symptoms = regionSymptoms[region] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2230),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _regionTitle(region, context.watch<TriageProvider>().selectedLanguage),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ...symptoms.map((symptom) {
                      final isSelected = selectedConceptKeys.contains(symptom.conceptKey);
                      final lang = context.watch<TriageProvider>().selectedLanguage;
                      final displayLabel = lang == 'en' ? symptom.englishLabel : symptom.hindiLabel;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setSheetState(() {
                              setState(() {
                                if (isSelected) {
                                  selectedConceptKeys.remove(symptom.conceptKey);
                                } else {
                                  selectedConceptKeys.add(symptom.conceptKey);
                                }
                              });
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.3) : const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFB0BEC5),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayLabel,
                                    style: const TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                        onPressed: () {
                          setState(() => activeRegion = null);
                          Navigator.pop(context);
                        },
                        child: Text(
                          context.watch<TriageProvider>().selectedLanguage == 'en' ? 'Close' : 'बंद करें',
                          style: const TextStyle(fontSize: 16, color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => activeRegion = null);
    });
  }

  String _regionTitle(String region, String lang) {
    if (lang == 'en') {
      switch (region) {
        case 'head': return 'Head Symptoms';
        case 'chest': return 'Chest Symptoms';
        case 'stomach': return 'Stomach / Pelvic Symptoms';
        case 'arms_hands': return 'Arms / Hands Symptoms';
        case 'legs_feet': return 'Legs / Feet Symptoms';
        case 'skin_whole_body': return 'Skin / Whole Body Symptoms';
        default: return 'Symptoms';
      }
    } else {
      switch (region) {
        case 'head': return 'सिर के लक्षण';
        case 'chest': return 'सीने के लक्षण';
        case 'stomach': return 'पेट के लक्षण';
        case 'arms_hands': return 'हाथों के लक्षण';
        case 'legs_feet': return 'पैरों के लक्षण';
        case 'skin_whole_body': return 'त्वचा / पूरे शरीर के लक्षण';
        default: return 'लक्षण';
      }
    }
  }

  void _onSubmit() {
    final List<DetectedConcept> concepts = [];
    for (final key in selectedConceptKeys) {
      for (final regionList in regionSymptoms.values) {
        final match = regionList.where((s) => s.conceptKey == key).toList();
        if (match.isNotEmpty) {
          final symptom = match.first;
          concepts.add(DetectedConcept(
            conceptKey: symptom.conceptKey,
            hindiLabel: symptom.hindiLabel,
            englishLabel: symptom.englishLabel,
            confirmationQuestion: symptom.hindiQuestion,
            category: symptom.category,
            similarity: 1.0,
            weight: symptom.weight,
            requiresConfirmation: symptom.category != 'GREEN',
            confirmed: false,
          ));
          break;
        }
      }
    }

    final provider = Provider.of<TriageProvider>(context, listen: false);
    provider.addManualBodyConcepts(concepts);

    final lang = provider.selectedLanguage;
    final successMsg = lang == 'en' ? 'Symptoms added to triage!' : 'लक्षण जोड़ दिए गए हैं!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF388E3C),
        duration: const Duration(seconds: 2),
      )
    );

    Navigator.pop(context);
  }

  Color _getCategoryColor(String category) {
    if (category == 'RED') return const Color(0xFFD32F2F);
    if (category == 'YELLOW') return const Color(0xFFF9A825);
    return const Color(0xFF388E3C);
  }

  Color? _getRegionColorIndicator(String region) {
    final regionKeys = regionSymptoms[region]?.map((s) => s.conceptKey) ?? [];
    final selectedInRegion = selectedConceptKeys.intersection(regionKeys.toSet());
    if (selectedInRegion.isEmpty) return null;

    bool hasRed = false;
    bool hasYellow = false;
    for (var key in selectedInRegion) {
      final symptom = regionSymptoms[region]!.firstWhere((s) => s.conceptKey == key);
      if (symptom.category == 'RED') hasRed = true;
      if (symptom.category == 'YELLOW') hasYellow = true;
    }

    if (hasRed) return const Color(0xFFD32F2F);
    if (hasYellow) return const Color(0xFFF9A825);
    return const Color(0xFF388E3C);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2230),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.watch<TriageProvider>().selectedLanguage == 'en' ? 'Tap Body Region' : 'शरीर पर दिखाएं',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.watch<TriageProvider>().selectedLanguage == 'en' ? 'Tap on the body area where you feel discomfort' : 'जहां तकलीफ है वहां दबाएं',
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center
            ),
          ),
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: BodyOutlinePainter(),
                    ),
                    Positioned.fill(
                      child: Column(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showSymptomSheet(context, 'head'),
                              child: Stack(
                                children: [
                                  Container(color: Colors.transparent),
                                  if (_getRegionColorIndicator('head') != null)
                                    Positioned(
                                      right: constraints.maxWidth / 3,
                                      top: 20,
                                      child: Icon(Icons.circle, color: _getRegionColorIndicator('head'), size: 16),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _showSymptomSheet(context, 'arms_hands'),
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _showSymptomSheet(context, 'chest'),
                                          child: Stack(
                                            children: [
                                              Container(color: Colors.transparent),
                                              if (_getRegionColorIndicator('chest') != null)
                                                Positioned(
                                                  right: 10,
                                                  top: 20,
                                                  child: Icon(Icons.circle, color: _getRegionColorIndicator('chest'), size: 16),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _showSymptomSheet(context, 'stomach'),
                                          child: Stack(
                                            children: [
                                              Container(color: Colors.transparent),
                                              if (_getRegionColorIndicator('stomach') != null)
                                                Positioned(
                                                  right: 10,
                                                  top: 20,
                                                  child: Icon(Icons.circle, color: _getRegionColorIndicator('stomach'), size: 16),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _showSymptomSheet(context, 'arms_hands'),
                                    child: Stack(
                                      children: [
                                        Container(color: Colors.transparent),
                                        if (_getRegionColorIndicator('arms_hands') != null)
                                          Positioned(
                                            left: 10,
                                            top: 40,
                                            child: Icon(Icons.circle, color: _getRegionColorIndicator('arms_hands'), size: 16),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showSymptomSheet(context, 'legs_feet'),
                              child: Stack(
                                children: [
                                  Container(color: Colors.transparent),
                                  if (_getRegionColorIndicator('legs_feet') != null)
                                    Positioned(
                                      right: constraints.maxWidth / 3,
                                      top: 40,
                                      child: Icon(Icons.circle, color: _getRegionColorIndicator('legs_feet'), size: 16),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1565C0)),
              ),
              onPressed: () => _showSymptomSheet(context, 'skin_whole_body'),
              icon: const Icon(Icons.water_drop_outlined, color: Colors.white),
              label: Text(
                context.watch<TriageProvider>().selectedLanguage == 'en' ? 'Skin / Whole Body Symptoms' : 'त्वचा / पूरे शरीर के लक्षण',
                style: const TextStyle(color: Colors.white)
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1C2230), borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(maxHeight: 100),
            child: selectedConceptKeys.isEmpty
                ? Center(
                    child: Text(
                      context.watch<TriageProvider>().selectedLanguage == 'en' ? 'No symptoms selected yet' : 'अभी तक कोई लक्षण नहीं चुना',
                      style: const TextStyle(fontSize: 14, color: Color(0xFFB0BEC5))
                    )
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedConceptKeys.map((key) {
                        BodyRegionSymptom? symptom;
                        for (final list in regionSymptoms.values) {
                          try {
                            symptom = list.firstWhere((s) => s.conceptKey == key);
                            break;
                          } catch (e) {}
                        }
                        if (symptom == null) return const SizedBox();
                        final lang = context.watch<TriageProvider>().selectedLanguage;
                        final displayLabel = lang == 'en' ? symptom.englishLabel : symptom.hindiLabel;

                        return Chip(
                          label: Text(displayLabel, style: const TextStyle(color: Colors.white)),
                          backgroundColor: _getCategoryColor(symptom.category).withOpacity(0.3),
                          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onDeleted: () => setState(() => selectedConceptKeys.remove(key)),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedConceptKeys.isEmpty ? Colors.grey : const Color(0xFF1565C0),
                ),
                onPressed: selectedConceptKeys.isEmpty ? null : _onSubmit,
                child: Text(
                  context.watch<TriageProvider>().selectedLanguage == 'en' ? 'Submit' : 'जमा करें',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Glowing core gradient for the body parts
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1565C0).withOpacity(0.15);

    // Sharp outer border
    final strokePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Soft neon glow under the borders
    final glowPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Helper to draw anatomical parts with the premium layered glow
    void drawPathWithGlow(Path path) {
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, strokePaint);
    }

    // 1. Head
    final headRect = Rect.fromCenter(center: Offset(centerX, size.height * 0.12), width: size.width * 0.22, height: size.height * 0.16);
    final headPath = Path()..addOval(headRect);
    drawPathWithGlow(headPath);

    // 2. Neck
    final neckPath = Path()
      ..moveTo(centerX - size.width * 0.06, size.height * 0.20)
      ..lineTo(centerX + size.width * 0.06, size.height * 0.20)
      ..lineTo(centerX + size.width * 0.08, size.height * 0.25)
      ..lineTo(centerX - size.width * 0.08, size.height * 0.25)
      ..close();
    drawPathWithGlow(neckPath);

    // 3. Torso
    final torsoPath = Path()
      ..moveTo(centerX - size.width * 0.18, size.height * 0.25) // Left shoulder
      ..lineTo(centerX + size.width * 0.18, size.height * 0.25) // Right shoulder
      ..quadraticBezierTo(centerX + size.width * 0.2, size.height * 0.4, centerX + size.width * 0.15, size.height * 0.55) // Right waist
      ..lineTo(centerX - size.width * 0.15, size.height * 0.55) // Left waist
      ..quadraticBezierTo(centerX - size.width * 0.2, size.height * 0.4, centerX - size.width * 0.18, size.height * 0.25) // Left torso edge
      ..close();
    drawPathWithGlow(torsoPath);

    // 4. Arms
    // Left Arm (A-pose / sideways)
    final leftArmPath = Path()
      ..moveTo(centerX - size.width * 0.18, size.height * 0.25) // Top of shoulder
      ..quadraticBezierTo(centerX - size.width * 0.30, size.height * 0.32, centerX - size.width * 0.38, size.height * 0.45) // Outer arm to hand
      ..lineTo(centerX - size.width * 0.34, size.height * 0.48) // Hand thickness
      ..quadraticBezierTo(centerX - size.width * 0.25, size.height * 0.38, centerX - size.width * 0.18, size.height * 0.32) // Inner arm back to armpit
      ..close();
    drawPathWithGlow(leftArmPath);
    
    // Right Arm (A-pose / sideways)
    final rightArmPath = Path()
      ..moveTo(centerX + size.width * 0.18, size.height * 0.25) // Top of shoulder
      ..quadraticBezierTo(centerX + size.width * 0.30, size.height * 0.32, centerX + size.width * 0.38, size.height * 0.45) // Outer arm to hand
      ..lineTo(centerX + size.width * 0.34, size.height * 0.48) // Hand thickness
      ..quadraticBezierTo(centerX + size.width * 0.25, size.height * 0.38, centerX + size.width * 0.18, size.height * 0.32) // Inner arm back to armpit
      ..close();
    drawPathWithGlow(rightArmPath);

    // 5. Legs
    // Left Leg
    final leftLegPath = Path()
      ..moveTo(centerX - size.width * 0.15, size.height * 0.55)
      ..lineTo(centerX - size.width * 0.02, size.height * 0.55)
      ..lineTo(centerX - size.width * 0.05, size.height * 0.85)
      ..lineTo(centerX - size.width * 0.15, size.height * 0.85)
      ..close();
    drawPathWithGlow(leftLegPath);

    // Right Leg
    final rightLegPath = Path()
      ..moveTo(centerX + size.width * 0.15, size.height * 0.55)
      ..lineTo(centerX + size.width * 0.02, size.height * 0.55)
      ..lineTo(centerX + size.width * 0.05, size.height * 0.85)
      ..lineTo(centerX + size.width * 0.15, size.height * 0.85)
      ..close();
    drawPathWithGlow(rightLegPath);

    // 6. Draw High-Tech Joints / Nodes
    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final jointGlow = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final joints = [
      Offset(centerX - size.width * 0.18, size.height * 0.25), // L Shoulder
      Offset(centerX + size.width * 0.18, size.height * 0.25), // R Shoulder
      Offset(centerX - size.width * 0.28, size.height * 0.35), // L Elbow
      Offset(centerX + size.width * 0.28, size.height * 0.35), // R Elbow
      Offset(centerX - size.width * 0.36, size.height * 0.46), // L Hand
      Offset(centerX + size.width * 0.36, size.height * 0.46), // R Hand
      Offset(centerX - size.width * 0.1, size.height * 0.55),  // L Hip
      Offset(centerX + size.width * 0.1, size.height * 0.55),  // R Hip
      Offset(centerX - size.width * 0.1, size.height * 0.85),  // L Foot
      Offset(centerX + size.width * 0.1, size.height * 0.85),  // R Foot
      Offset(centerX, size.height * 0.20),                     // Neck Center
      Offset(centerX, size.height * 0.40),                     // Solar Plexus
    ];

    for (final joint in joints) {
      canvas.drawCircle(joint, 6, jointGlow);
      canvas.drawCircle(joint, 3, jointPaint);
    }

    // 7. Futuristic Horizontal Medical Scanning Lines
    final scanLinePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (double y = size.height * 0.05; y < size.height * 0.95; y += 12) {
      canvas.drawLine(Offset(centerX - size.width * 0.4, y), Offset(centerX + size.width * 0.4, y), scanLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
