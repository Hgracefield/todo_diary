# WriteLog API 명세서

Flutter 프론트엔드와 FastAPI 백엔드로 구성된 일정·다이어리 앱의 실제 구현 코드를 기준으로 작성한 API 명세서입니다.

- 분석 범위: `backend/main.py`, `backend/routers/`, `backend/schemas.py`, `backend/crud.py`, `backend/models.py`
- 직접 선언된 API: 총 24개
- Base URL 예시: `http://127.0.0.1:8000`
- API 공통 Prefix: `/api`
- 작성 기준: 코드에서 확인할 수 없는 내용은 `확인 필요`로 표기

## 1. 프로젝트 구조

```text
todo_diary/
├── lib/                          # Flutter 프론트엔드
│   ├── api/
│   │   ├── api_client.dart       # HTTP 요청 공통 처리
│   │   ├── api_config.dart       # API Base URL
│   │   └── rest_api_service.dart # 백엔드 API 호출
│   ├── model/server/             # API 응답 모델
│   ├── storage/                  # 로그인 사용자 정보 저장
│   ├── view/                     # 화면
│   └── vm/database_handler.dart  # API·로컬 DB 연동
│
└── backend/                      # FastAPI 백엔드
    ├── main.py                   # 앱 생성, Router 등록, 공통 API
    ├── database.py               # MySQL·SQLAlchemy 연결
    ├── models.py                 # SQLAlchemy DB 모델
    ├── schemas.py                # Pydantic 요청·응답 스키마
    ├── crud.py                   # 데이터 조회·생성·수정·삭제
    └── routers/
        ├── users.py              # 사용자 API
        ├── schedules.py          # 일정·일정 분류 API
        ├── diaries.py            # 다이어리 API
        └── images.py             # 다이어리 이미지 API
```

모든 router에는 `backend/main.py`에서 `/api` prefix가 추가됩니다.

## 2. 공통 API

| 기능 분류 | 기능명 | HTTP Method | Endpoint | 요청 Parameter 또는 Request Body | Response | 성공 상태 코드 | 실패 상태 코드 | 인증 필요 여부 | 관련 파일 경로 |
|---|---|---|---|---|---|---:|---|---|---|
| 시스템 | 서버 상태 확인 | GET | `/` | 없음 | `{ message: string }` | 200 | 확인 필요 | 아니오 | `backend/main.py` |
| 시스템 | MySQL 연결 확인 | GET | `/db-test` | 없음 | `{ connected: true, message: string }` | 200 | 500: DB 연결 실패 | 아니오 | `backend/main.py`<br>`backend/database.py` |

## 3. 사용자 API

| 기능 분류 | 기능명 | HTTP Method | Endpoint | 요청 Parameter 또는 Request Body | Response | 성공 상태 코드 | 실패 상태 코드 | 인증 필요 여부 | 관련 파일 경로 |
|---|---|---|---|---|---|---:|---|---|---|
| 사용자 | 회원가입 | POST | `/api/users` | Body: `UserCreate` | `UserRead` | 201 | 409: 이메일·전화번호 중복<br>422: 요청 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 사용자 | 로그인 | POST | `/api/users/login` | Body: `{ userEmail, userPassword }` | `UserRead` | 200 | 401: 이메일 또는 비밀번호 불일치<br>422: 요청 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/crud.py` |
| 사용자 | 가입 이메일 찾기 | POST | `/api/users/find-account` | Body: `{ userName, userPhone }` | `{ userEmail: string }` | 200 | 404: 일치하는 회원 없음<br>422: 요청 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/crud.py` |
| 사용자 | 이메일 중복 확인 | GET | `/api/users/check-email` | Query: `email` 필수 | `{ available: boolean }` | 200 | 422: 누락·빈 문자열 | 아니오 | `backend/routers/users.py`<br>`backend/crud.py` |
| 사용자 | 전화번호 중복 확인 | GET | `/api/users/check-phone` | Query: `phone` 필수<br>`excludeUserId` 선택 | `{ available: boolean }` | 200 | 422: 요청 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/crud.py` |
| 사용자 | 사용자 정보 조회 | GET | `/api/users/{user_id}` | Path: `user_id: int` | `UserRead` | 200 | 404: 사용자 없음<br>422: Path 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/crud.py` |
| 사용자 | 사용자 정보 수정 | PATCH | `/api/users/{user_id}` | Path: `user_id`<br>Body: `UserUpdate` | `UserRead` | 200 | 404: 사용자 없음<br>409: 전화번호 중복<br>422: 요청 검증 실패 | 아니오 | `backend/routers/users.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 사용자 | 비밀번호 변경 | PATCH | `/api/users/{user_id}/password` | Path: `user_id`<br>Body: `{ currentPassword, newPassword }` | `UserRead` | 200 | 401: 현재 비밀번호 불일치<br>404: 사용자 없음<br>422: 요청 검증 실패 | 별도 인증 없음<br>현재 비밀번호만 검증 | `backend/routers/users.py`<br>`backend/crud.py` |

## 4. 일정 및 일정 분류 API

| 기능 분류 | 기능명 | HTTP Method | Endpoint | 요청 Parameter 또는 Request Body | Response | 성공 상태 코드 | 실패 상태 코드 | 인증 필요 여부 | 관련 파일 경로 |
|---|---|---|---|---|---|---:|---|---|---|
| 일정 분류 | 일정 분류 목록 조회 | GET | `/api/schedule-types` | 없음 | `ScheduleTypeRead[]` | 200 | 확인 필요 | 아니오 | `backend/routers/schedules.py`<br>`backend/crud.py` |
| 일정 분류 | 일정 분류 등록 | POST | `/api/schedule-types` | Body: `{ scheduleTypeName, scheduleTypeColor }` | `ScheduleTypeRead` | 201 | 422: 요청 검증 실패 | 아니오 | `backend/routers/schedules.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 일정 | 사용자 일정 목록 조회 | GET | `/api/schedules` | Query: `userId` 필수<br>`startDate`, `endDate` 선택 (`YYYY-MM-DD`) | `ScheduleRead[]` | 200 | 422: 요청 검증 실패 | 아니오 | `backend/routers/schedules.py`<br>`backend/crud.py` |
| 일정 | 일정 등록 | POST | `/api/schedules` | Body: `ScheduleCreate` | `ScheduleRead` | 201 | 422: 요청 검증 실패 | 아니오 | `backend/routers/schedules.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 일정 | 일정 수정·완료 처리 | PATCH | `/api/schedules/{schedule_id}` | Path: `schedule_id`<br>Body: `ScheduleUpdate` | `ScheduleRead` | 200 | 404: 일정 없음<br>422: 요청 검증 실패 | 아니오 | `backend/routers/schedules.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 일정 | 일정 삭제 | DELETE | `/api/schedules/{schedule_id}` | Path: `schedule_id: int` | Body 없음 | 204 | 404: 일정 없음<br>422: Path 검증 실패 | 아니오 | `backend/routers/schedules.py`<br>`backend/crud.py` |

`startDate`와 `endDate`는 일정의 `scheduleStartDate`를 기준으로 필터링합니다. 두 날짜를 같은 값으로 전달하면 해당 날짜의 일정만 조회됩니다.

## 5. 다이어리 API

| 기능 분류 | 기능명 | HTTP Method | Endpoint | 요청 Parameter 또는 Request Body | Response | 성공 상태 코드 | 실패 상태 코드 | 인증 필요 여부 | 관련 파일 경로 |
|---|---|---|---|---|---|---:|---|---|---|
| 다이어리 | 사용자 다이어리 목록 조회 | GET | `/api/diaries` | Query: `userId` 필수<br>`startDate`, `endDate` 선택 (`YYYY-MM-DD`) | `DiaryRead[]` | 200 | 422: 요청 검증 실패 | 아니오 | `backend/routers/diaries.py`<br>`backend/crud.py` |
| 다이어리 | 특정 날짜 다이어리 조회 | GET | `/api/diaries/by-date` | Query: `userId` 필수<br>`date` 필수 (`YYYY-MM-DD`) | `DiaryRead` | 200 | 404: 일기 없음<br>422: 요청 검증 실패 | 아니오 | `backend/routers/diaries.py`<br>`backend/crud.py` |
| 다이어리 | 다이어리 등록 | POST | `/api/diaries` | Body: `DiaryCreate` | `DiaryRead` | 201 | 400: 미래 날짜<br>409: 해당 날짜의 일기 중복<br>422: 요청 검증 실패 | 아니오 | `backend/routers/diaries.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 다이어리 | 다이어리 수정 | PATCH | `/api/diaries/{diary_id}` | Path: `diary_id`<br>Body: `DiaryUpdate` | `DiaryRead` | 200 | 400: 미래 날짜<br>404: 일기 없음<br>422: 요청 검증 실패 | 아니오 | `backend/routers/diaries.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 다이어리 | 다이어리 삭제 | DELETE | `/api/diaries/{diary_id}` | Path: `diary_id: int` | Body 없음 | 204 | 404: 일기 없음<br>422: Path 검증 실패 | 아니오 | `backend/routers/diaries.py`<br>`backend/crud.py` |

## 6. 다이어리 이미지 API

| 기능 분류 | 기능명 | HTTP Method | Endpoint | 요청 Parameter 또는 Request Body | Response | 성공 상태 코드 | 실패 상태 코드 | 인증 필요 여부 | 관련 파일 경로 |
|---|---|---|---|---|---|---:|---|---|---|
| 다이어리 이미지 | 다이어리 이미지 조회 | GET | `/api/diaries/{diary_id}/images` | Path: `diary_id: int` | `DiaryImageRead[]` | 200 | 404: 일기 없음<br>422: Path 검증 실패 | 아니오 | `backend/routers/images.py`<br>`backend/crud.py` |
| 다이어리 이미지 | 다이어리 이미지 등록 | POST | `/api/diaries/{diary_id}/images` | Path: `diary_id`<br>Body: `DiaryImageCreate` | `DiaryImageRead` | 201 | 400: Path와 Body의 일기 ID 불일치<br>404: 일기 없음<br>422: 요청 검증 실패 | 아니오 | `backend/routers/images.py`<br>`backend/schemas.py`<br>`backend/crud.py` |
| 다이어리 이미지 | 다이어리 이미지 삭제 | DELETE | `/api/diaries/{diary_id}/images/{image_id}` | Path: `diary_id`, `image_id` | Body 없음 | 204 | 404: 일기 또는 연결 이미지 없음<br>422: Path 검증 실패 | 아니오 | `backend/routers/images.py`<br>`backend/crud.py` |

현재 DB 모델상 다이어리에는 `diaryImageId` 하나만 연결되므로, 응답 형식은 배열이지만 실제 CRUD 구현에서는 최대 이미지 1개만 반환합니다.

## 7. 요청 Body 상세

모든 JSON 필드는 camelCase가 기본 응답 형식입니다. Pydantic 설정상 snake_case 입력도 허용됩니다.

| Schema | 필드 |
|---|---|
| `UserCreate` | `userName: string` 필수, 1~45자<br>`userEmail: string` 필수, 1~45자<br>`userPassword: string` 필수, 1~255자<br>`userPhone: string?`, 최대 20자<br>`userAddress: string?`, 최대 45자<br>`userBirthDate: date?` |
| `UserUpdate` | `userName?: string`, 1~45자<br>`userPhone?: string`, 최대 20자<br>`userAddress?: string`, 최대 45자<br>`userBirthDate?: date` |
| `ScheduleTypeCreate` | `scheduleTypeName: string` 필수, 1~45자<br>`scheduleTypeColor: string` 필수, 1~45자 |
| `ScheduleCreate` | `userId: int` 필수<br>`scheduleTypeId: int` 필수<br>`scheduleTitle: string` 필수, 1~45자<br>`scheduleContent?: string`, 최대 45자<br>`scheduleStartDate: datetime` 필수<br>`scheduleEndDate: datetime` 필수<br>`scheduleIsDone: boolean`, 기본값 `false` |
| `ScheduleUpdate` | `scheduleTypeId?: int`<br>`scheduleTitle?: string`, 1~45자<br>`scheduleContent?: string`, 최대 45자<br>`scheduleStartDate?: datetime`<br>`scheduleEndDate?: datetime`<br>`scheduleIsDone?: boolean` |
| `DiaryCreate` | `userId: int` 필수<br>`diaryDate: datetime` 필수<br>`diaryTitle: string`, 기본값 `""`, 최대 45자<br>`diaryContent?: string`, 최대 45자 |
| `DiaryUpdate` | `diaryDate?: datetime`<br>`diaryTitle?: string`, 최대 45자<br>`diaryContent?: string`, 최대 45자 |
| `DiaryImageCreate` | `diaryId: int` 필수<br>`diaryImageUrl: string` 필수, 1~45자<br>`diaryImageOrder: int`, 기본값 `0`<br>`diaryImageIsRepresentative: boolean`, 기본값 `false` |

## 8. Response 상세

| Schema | 필드 |
|---|---|
| `UserRead` | `userId`, `userName`, `userEmail`, `userPhone`, `userAddress`, `userBirthDate`, `userCreateAt`, `userUpdatedAt` |
| `ScheduleTypeRead` | `scheduleTypeId`, `scheduleTypeName`, `scheduleTypeColor`, `scheduleTypeCreateAt` |
| `ScheduleRead` | `scheduleId`, `userId`, `scheduleTypeId`, `scheduleTitle`, `scheduleContent`, `scheduleStartDate`, `scheduleEndDate`, `scheduleIsDone`, `scheduleCreatedAt`, `scheduleUpdatedAt` |
| `DiaryRead` | `diaryId`, `userId`, `diaryDate`, `diaryTitle`, `diaryContent`, `diaryCreatedAt`, `diaryUpdatedAt` |
| `DiaryImageRead` | `diaryId`, `diaryImageId`, `diaryImageUrl`, `diaryImageOrder`, `diaryImageIsRepresentative`, `diaryImageCreatedAt` |
| 오류 응답 | 일반 오류: `{ "detail": "오류 메시지" }`<br>422 검증 오류: FastAPI `HTTPValidationError` 형식 |

## 9. 분석 시 확인된 사항

- JWT, 세션 쿠키, OAuth 또는 인증 dependency가 구현되어 있지 않습니다.
- `userId`를 전달해 사용자 데이터를 조회하지만 요청자의 신원을 검증하지는 않습니다.
- 비밀번호 변경 API만 Body의 `currentPassword`를 확인합니다.
- 명시적인 비즈니스 예외가 없는 API는 실패 상태를 `확인 필요`로 표시했습니다.
- 예상하지 못한 DB·서버 오류는 일반적으로 500이 될 수 있지만, route별 오류 계약이 코드에 정의되어 있지 않아 표에 임의로 추가하지 않았습니다.
- FastAPI가 자동 제공하는 `/docs`, `/redoc`, `/openapi.json`은 프레임워크 문서 경로이므로 24개 비즈니스 API 수에는 포함하지 않았습니다.
- API 오류 응답의 공통 포맷이나 전역 예외 처리기는 별도로 구현되어 있지 않습니다.

## 10. 분석 근거 파일

- `backend/main.py`
- `backend/database.py`
- `backend/models.py`
- `backend/schemas.py`
- `backend/crud.py`
- `backend/routers/users.py`
- `backend/routers/schedules.py`
- `backend/routers/diaries.py`
- `backend/routers/images.py`
- `lib/api/api_client.dart`
- `lib/api/rest_api_service.dart`

