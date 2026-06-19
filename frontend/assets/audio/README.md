# Audio Assets

Place the following Hindi TTS audio files here:
- `red_hindi.mp3`   — "यह बहुत गंभीर मामला है। मरीज को तुरंत अस्पताल ले जाएं।"
- `yellow_hindi.mp3` — "मरीज की जांच जरूरी है। कल PHC में ले जाएं।"
- `green_hindi.mp3`  — "सामान्य स्थिति है। घर पर आराम करें और निगरानी रखें।"

## Generate these files using:
- Google TTS (gTTS Python library)
- Amazon Polly (Hindi - Aditi voice)
- ElevenLabs Hindi TTS

## Quick Python script to generate:
```python
from gtts import gTTS
texts = {
    "red_hindi": "यह बहुत गंभीर मामला है। मरीज को तुरंत अस्पताल ले जाएं।",
    "yellow_hindi": "मरीज की जांच जरूरी है। कल PHC में ले जाएं।",
    "green_hindi": "सामान्य स्थिति है। घर पर आराम करें और निगरानी रखें।",
}
for name, text in texts.items():
    tts = gTTS(text=text, lang='hi')
    tts.save(f"{name}.mp3")
```
