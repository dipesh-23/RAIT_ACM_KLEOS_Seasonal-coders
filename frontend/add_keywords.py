import json
import os

FILE_PATH = 'd:/RAIT_HACK/frontend/assets/anchors/clinical_anchors.json'

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Hardcoded expansions
expansion_dict = {
    "breathing_difficulty": {
        "hi": ["सांस", "साँस", "दम", "सांस फूलना", "सांस लेने में दिक्कत", "सांस रुक", "सांस की तकलीफ", "घबराहट", "दमा", "हाफनी", "हाँफ रहा", "सांस लेने में परेशानी", "साँस लेने में समस्या"],
        "en": ["breath", "breathing", "choking", "gasping", "wheezing", "asthma", "breathless", "suffocating", "can't breathe", "short of breath", "panting"]
    },
    "unconscious": {
        "hi": ["बेहोश", "बेसुध", "चक्कर खाकर गिर", "होश नहीं", "होश में नहीं", "जवाब नहीं दे रहा", "मूर्छित", "सुध-बुध नहीं", "आवाज नहीं सुन रहा"],
        "en": ["unconscious", "passed out", "fainted", "unresponsive", "not waking up", "blacked out", "coma", "senseless"]
    },
    "seizure": {
        "hi": ["दौरा", "दौरे", "मिर्गी", "ऐंठन", "झटके", "मुंह से झाग", "दांत भींच", "शरीर अकड़", "कंपकंपी"],
        "en": ["seizure", "seizures", "convulsion", "convulsions", "fits", "shaking", "frothing", "epilepsy", "twitching"]
    },
    "severe_bleeding": {
        "hi": ["खून बह", "बहुत खून", "रक्तस्राव", "भयंकर खून", "खून नहीं रुक", "कट गया और खून", "रक्त बह रहा", "भारी खून", "लगातार खून", "कटा हुआ", "चोट और खून"],
        "en": ["bleeding heavily", "severe bleeding", "blood not stopping", "gushing blood", "hemorrhage", "profuse bleeding", "losing blood", "cut deep"]
    },
    "chest_pain": {
        "hi": ["सीने में दर्द", "छाती में दर्द", "दिल में दर्द", "छाती में भारीपन", "सीने में जलन", "हार्ट अटैक", "दिल का दौरा", "छाती जकड़", "छाती दर्द"],
        "en": ["chest pain", "heart attack", "heart pain", "chest heaviness", "tight chest", "chest burning", "angina"]
    },
    "newborn_emergency": {
        "hi": ["बच्चा रो नहीं", "बच्चा पीला", "नवजात", "पैदा हुआ बच्चा", "बच्चा नीला", "बच्चा दूध नहीं पी"],
        "en": ["newborn", "baby not crying", "baby turning blue", "baby not feeding", "infant emergency"]
    },
    "labor_complication": {
        "hi": ["प्रसव", "डिलीवरी", "बच्चा दाने", "पेट में भयंकर दर्द", "पानी की थैली", "दर्द शुरू", "डिलीवरी होने वाली"],
        "en": ["labor", "delivery", "water broke", "contractions", "pregnant bleeding", "giving birth"]
    },
    "not_eating_drinking": {
        "hi": ["खाना-पीना छोड़", "कुछ नहीं खा रहा", "कुछ नहीं पी रहा", "निगल नहीं पा रहा", "मुंह नहीं खोल रहा", "भूख नहीं"],
        "en": ["not eating", "not drinking", "stopped eating", "stopped drinking", "can't swallow", "no appetite"]
    },
    "high_fever_prolonged": {
        "hi": ["कई दिनों से बुखार", "बुखार नहीं उतर रहा", "तेज बुखार", "लगातार बुखार", "हफ्तों से बुखार", "शरीर तप रहा"],
        "en": ["high fever", "fever for days", "fever not going down", "prolonged fever", "burning hot"]
    },
    "fever_high": {
        "hi": ["बहुत तेज बुखार", "शरीर जल रहा", "बुखार 102", "बुखार 103", "भयंकर बुखार", "तप रहा है"],
        "en": ["very high fever", "burning hot", "fever 103", "fever 102", "extremely hot"]
    },
    "repeated_vomiting": {
        "hi": ["लगातार उल्टी", "बार-बार उल्टी", "उल्टियां", "पलटी", "कुछ पच नहीं रहा", "उल्टी रुक नहीं"],
        "en": ["vomiting repeatedly", "throwing up", "can't keep food down", "puking", "continuous vomiting"]
    },
    "severe_diarrhea": {
        "hi": ["लगातार दस्त", "पानी जैसे दस्त", "बार-बार दस्त", "पतले दस्त", "पेट खराब", "लूज मोशन", "दस्त रुक नहीं"],
        "en": ["severe diarrhea", "loose motions", "watery stool", "diarrhea", "can't stop pooping", "runs"]
    },
    "severe_headache": {
        "hi": ["सिर फटने", "बहुत तेज सिरदर्द", "माथा दर्द", "भयंकर सिर दर्द", "माइग्रेन", "सिर दर्द बर्दाश्त नहीं"],
        "en": ["severe headache", "head splitting", "terrible headache", "migraine", "worst headache"]
    },
    "pregnancy_concern": {
        "hi": ["गर्भवती", "पेट में बच्चा", "प्रेगनेंसी", "प्रेगनेंट", "गर्भावस्था", "बच्चे की हलचल नहीं"],
        "en": ["pregnancy", "pregnant", "baby not moving", "bleeding during pregnancy"]
    },
    "child_lethargic": {
        "hi": ["बच्चा सुस्त", "बच्चा खेल नहीं", "बच्चा सोता रह", "बच्चा निढाल", "बच्चा उठ नहीं रहा"],
        "en": ["child lethargic", "baby inactive", "child sleepy", "not playing", "sluggish child"]
    },
    "body_swelling": {
        "hi": ["शरीर में सूजन", "सूज गया", "पैर सूज", "हाथ-पैर सूज", "चेहरा सूज", "पूरा शरीर सूज"],
        "en": ["swelling", "body swollen", "swollen feet", "swollen face", "edema", "puffed up"]
    },
    "common_cold": {
        "hi": ["सर्दी", "जुकाम", "खांसी", "हल्की खांसी", "नाक बह", "गला खराब"],
        "en": ["cold", "cough", "runny nose", "sore throat", "sneezing", "mild cough"]
    },
    "minor_body_ache": {
        "hi": ["बदन दर्द", "हाथ पैर दर्द", "हल्का दर्द", "थकान", "शरीर टूट रहा"],
        "en": ["body ache", "muscle pain", "tiredness", "mild pain", "fatigue", "body hurting"]
    },
    "minor_stomach_ache": {
        "hi": ["पेट दर्द", "हल्का पेट दर्द", "पेट में गैस", "गैस बन रही", "पेट फूल"],
        "en": ["stomach ache", "belly pain", "mild stomach pain", "gas", "bloated"]
    },
    "snakebite_animal_bite": {
        "hi": ["सांप ने काट", "सांप", "जानवर ने काट", "कुत्ते ने काट", "बंदर ने काट", "बिच्छू"],
        "en": ["snake bite", "snake", "animal bite", "dog bite", "scorpion", "bitten by"]
    },
    "severe_dehydration": {
        "hi": ["पानी की कमी", "आंखें धंस", "मुंह सूख", "पेशाब नहीं आ रहा", "बहुत कमजोरी"],
        "en": ["dehydration", "sunken eyes", "dry mouth", "not peeing", "extreme weakness"]
    },
    "fever_mild": {
        "hi": ["हल्का बुखार", "थोड़ा बुखार", "गरम लग रहा", "बुखार जैसा लग रहा"],
        "en": ["mild fever", "slight fever", "low grade temperature", "slightly warm"]
    },
    "fever_with_seizure": {
        "hi": ["बुखार और झटके", "बुखार के साथ दौरे", "बुखार से ऐंठन", "ताप और झटके"],
        "en": ["fever and seizure", "fever with shaking", "febrile seizure", "fever convulsion"]
    }
}

for anchor in data['anchors']:
    key = anchor['key']
    
    # Init english keywords array
    if "english_keywords" not in anchor:
        anchor["english_keywords"] = []
    
    # Split the concept string into individual english keywords automatically
    words = [w for w in anchor['concept'].split() if len(w) > 3]
    anchor["english_keywords"].extend(words)

    # Apply hardcoded expansions if any
    if key in expansion_dict:
        hi_words = expansion_dict[key].get("hi", [])
        en_words = expansion_dict[key].get("en", [])
        anchor["hindi_keywords"].extend(hi_words)
        anchor["english_keywords"].extend(en_words)

    # De-duplicate
    anchor["hindi_keywords"] = list(set(anchor["hindi_keywords"]))
    anchor["english_keywords"] = list(set(anchor["english_keywords"]))

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Keywords expanded successfully!")
