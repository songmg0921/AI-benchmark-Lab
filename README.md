# AI Benchmark Lab

브라우저에서 사용자의 CPU, GPU, AI 추론 및 네트워크 성능을 측정하는 FastAPI 기반 벤치마크 서비스입니다. 하드웨어 정보는 브라우저가 허용하는 범위에서만 자동 수집하며, 정확한 사양은 선택적으로 사용자가 입력합니다.

## 기능

- Web Worker 기반 CPU 정수/부동소수점 반복 연산 측정
- WebGPU Compute Shader 지원 여부 및 GPU 작업 시간 측정
- 네트워크 RTT, jitter, 다운로드/업로드 속도 측정
- 0~1000 범위의 잠정 점수와 원본 JSON 결과 다운로드
- 브라우저 내부에서 실행되며 사용자 동의 없이 결과를 서버에 저장하지 않음

현재 배포본에서는 ONNX Runtime Web 모델 추론 영역을 확장할 수 있도록 결과 구조를 포함하고 있으며, 검증된 모델 URL과 무결성 검증값을 준비한 뒤 연결해야 합니다. 모델 파일은 저장소에 포함하지 않습니다.

## 요구 사항

- Windows의 기존 Python 3.11 이상 권장
- Python 가상환경 없이도 실행 가능
- 최신 Chromium 계열 브라우저 권장

## 설치 및 실행

PowerShell에서 프로젝트 루트(`upload`)로 이동한 뒤 실행합니다.

```powershell
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

브라우저에서 <http://127.0.0.1:8000>을 엽니다.

## 테스트

```powershell
python -m pytest -q
```

## 모델 준비 방법

대용량 모델은 저장소에 넣지 않습니다. ONNX Runtime Web을 추가할 때 다음을 확인하세요.

1. MobileNet 계열의 경량 ONNX 모델을 공식 배포처 또는 신뢰할 수 있는 릴리스에서 선택합니다.
2. 모델의 버전, 출처, 라이선스, SHA-256 해시를 기록합니다.
3. HTTPS 모델 URL을 사용하고 브라우저의 CORS 허용 여부를 확인합니다.
4. WASM CPU와 WebGPU 백엔드에서 같은 모델·입력·반복 횟수로 워밍업 및 추론 시간을 측정합니다.
5. 다운로드/로딩 시간과 순수 추론 시간을 분리하여 표시합니다.

모델을 다운로드하거나 실행할 때 개인 파일을 업로드하지 않도록 입력 데이터는 브라우저에서 생성합니다.

## Docker

```powershell
docker compose up --build
```

이후 <http://127.0.0.1:8000>으로 접속합니다.

## API

- `GET /api/health`
- `GET /api/network/ping`
- `GET /api/network/download?size=262144`
- `POST /api/network/upload`

네트워크 결과는 해당 벤치마크 서버까지의 연결 상태를 나타내며, 인터넷 전체 품질이나 다른 서버의 성능을 의미하지 않습니다.

## 점수

CPU, GPU, AI, Network 점수는 0~1000의 잠정 점수이며 지원되지 않는 항목은 `N/A`입니다. 원본 측정값은 결과 JSON에 보존됩니다. 기준 데이터가 충분히 축적되기 전에는 백분위나 순위를 제공하지 않습니다.

## 개인정보 및 보안

인증정보, 개인 파일, 브라우저 캐시, 로그, 테스트 이미지 및 모델 파일은 이 배포 폴더에 포함하지 않습니다. 사용자가 명시적으로 공유를 선택하지 않는 한 결과를 서버에 저장하지 않는 구조를 기본으로 합니다.
