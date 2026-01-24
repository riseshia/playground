FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Python 3.12 설치
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    git \
    libsndfile1 \
    ffmpeg \
    sox \
    && rm -rf /var/lib/apt/lists/*

# Python 3.12을 기본으로 설정
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# pip 업그레이드
RUN python -m ensurepip --upgrade \
    && python -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# PyTorch 설치 (CUDA 12.4 호환)
RUN pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu124

# qwen-tts 및 의존성 설치
RUN pip install qwen-tts gradio soundfile numpy

# flash-attn 설치 (빌드 시간이 오래 걸림, 선택적)
# 빌드 시간 단축을 위해 주석 처리됨. 필요시 활성화
# ENV MAX_JOBS=4
# RUN pip install flash-attn --no-build-isolation

# 데모 스크립트 복사
COPY demo.py /app/demo.py

# Gradio 포트 노출
EXPOSE 7860

# 모델 캐시 디렉토리
ENV HF_HOME=/app/models

# 실행
CMD ["python", "demo.py"]
