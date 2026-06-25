# Life Log

Flutter 앱과 FastAPI/MySQL 백엔드로 구성되어 있습니다.

## 백엔드 실행

`backend/.env`에 Workbench에서 사용하는 MySQL 접속 정보를 입력합니다.

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=...
DB_PASSWORD=...
DB_NAME=...
```

프로젝트 루트에서 다음과 같이 실행합니다.

```bash
python3 -m pip install -r backend/requirements.txt
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8080
```

API 문서는 `http://127.0.0.1:8080/docs`에서 확인할 수 있습니다.

## Flutter 실행

로컬 기본 주소는 iOS/macOS에서 `127.0.0.1:8080`, Android 에뮬레이터에서
`10.0.2.2:8080`입니다. 실제 기기나 다른 서버를 사용할 때는 주소를 지정합니다.

```bash
flutter run --dart-define=API_BASE_URL=http://서버주소:8080/api
```

계정, 일정, 일기 텍스트는 API와 동기화됩니다. Workbench 스키마에 컬럼이 없는
일정 완료 상태와 여러 장의 일기 사진 원본은 현재 기기의 로컬 저장소에 유지됩니다.
