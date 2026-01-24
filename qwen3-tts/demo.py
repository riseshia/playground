#!/usr/bin/env python3
"""Qwen3-TTS Gradio 웹 데모"""

import gradio as gr
import torch
import soundfile as sf
import tempfile
from qwen_tts import Qwen3TTSModel

# 지원 언어 목록
LANGUAGES = {
    "한국어": "Korean",
    "English": "English",
    "中文": "Chinese",
    "日本語": "Japanese",
    "Deutsch": "German",
    "Français": "French",
    "Español": "Spanish",
    "Italiano": "Italian",
    "Português": "Portuguese",
    "Русский": "Russian",
}

# 모델 초기화
print("모델 로딩 중...")
model = Qwen3TTSModel.from_pretrained(
    "Qwen/Qwen3-TTS-12Hz-1.7B-Base",
    device_map="cuda:0",
    dtype=torch.bfloat16,
)
print("모델 로딩 완료!")


def generate_speech(
    text: str,
    language: str,
    reference_audio: str | None,
    reference_text: str,
) -> str | None:
    """텍스트를 음성으로 변환 (음성 클론)"""
    if not text.strip():
        gr.Warning("텍스트를 입력해주세요.")
        return None

    if not reference_audio:
        gr.Warning("참조 음성을 업로드해주세요. Base 모델은 음성 클론을 위해 참조 음성이 필요합니다.")
        return None

    if not reference_text.strip():
        gr.Warning("참조 음성의 텍스트를 입력해주세요.")
        return None

    try:
        lang_code = LANGUAGES.get(language, "Korean")

        wavs, sr = model.generate_voice_clone(
            text=text,
            language=lang_code,
            ref_audio=reference_audio,
            ref_text=reference_text,
        )

        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            sf.write(f.name, wavs[0], sr)
            return f.name

    except Exception as e:
        gr.Error(f"음성 생성 실패: {e}")
        import traceback
        traceback.print_exc()
        return None


def create_demo() -> gr.Blocks:
    """Gradio 데모 UI 생성"""
    with gr.Blocks(title="Qwen3-TTS Voice Clone Demo") as demo:
        gr.Markdown(
            """
            # Qwen3-TTS 음성 클론 데모

            참조 음성을 업로드하고, 해당 목소리로 새로운 텍스트를 읽어줍니다.

            **사용법:**
            1. 3초 정도의 깨끗한 음성 클립을 업로드
            2. 참조 음성에서 말하는 내용을 정확히 입력
            3. 생성할 텍스트 입력
            4. 음성 생성 버튼 클릭
            """
        )

        with gr.Row():
            with gr.Column(scale=1):
                gr.Markdown("### 참조 음성 (필수)")
                reference_audio = gr.Audio(
                    label="참조 음성 (3초 권장)",
                    type="filepath",
                )
                reference_text = gr.Textbox(
                    label="참조 음성의 텍스트",
                    placeholder="참조 음성에서 말하는 내용을 정확히 입력하세요...",
                    lines=2,
                )

                gr.Markdown("### 생성할 텍스트")
                text_input = gr.Textbox(
                    label="텍스트",
                    placeholder="생성할 텍스트를 입력하세요...",
                    lines=5,
                )
                language = gr.Dropdown(
                    choices=list(LANGUAGES.keys()),
                    value="한국어",
                    label="언어",
                )

                generate_btn = gr.Button("음성 생성", variant="primary")

            with gr.Column(scale=1):
                output_audio = gr.Audio(
                    label="생성된 음성",
                    type="filepath",
                )

        generate_btn.click(
            fn=generate_speech,
            inputs=[text_input, language, reference_audio, reference_text],
            outputs=output_audio,
        )

    return demo


if __name__ == "__main__":
    demo = create_demo()
    demo.launch(
        server_name="0.0.0.0",
        server_port=7860,
        share=False,
    )
