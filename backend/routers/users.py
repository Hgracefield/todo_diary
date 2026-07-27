from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

import crud
import schemas
from database import get_db

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=schemas.UserRead, status_code=status.HTTP_201_CREATED)
def create_user(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    if crud.email_exists(db, payload.user_email):
        raise HTTPException(status_code=409, detail="이미 사용 중인 이메일입니다.")
    if payload.user_phone and crud.phone_exists(db, payload.user_phone):
        raise HTTPException(status_code=409, detail="이미 사용 중인 전화번호입니다.")
    return crud.create_user(db, payload)


@router.post("/login", response_model=schemas.UserRead)
def login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, payload.user_email)
    if user is None or not crud.verify_password(
        payload.user_password, user.user_password
    ):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    return user


@router.post("/find-account", response_model=schemas.UserAccountLookupRead)
def find_account(
    payload: schemas.UserAccountLookup, db: Session = Depends(get_db)
):
    user = crud.get_user_by_name_and_phone(
        db,
        payload.user_name,
        payload.user_phone,
    )
    if user is None or not user.user_email:
        raise HTTPException(
            status_code=404,
            detail="일치하는 회원정보를 찾을 수 없습니다.",
        )
    return schemas.UserAccountLookupRead(user_email=user.user_email)


@router.get("/check-email", response_model=schemas.Availability)
def check_email(email: str = Query(min_length=1), db: Session = Depends(get_db)):
    return schemas.Availability(available=not crud.email_exists(db, email))


@router.get("/check-phone", response_model=schemas.Availability)
def check_phone(phone: str = Query(min_length=1), db: Session = Depends(get_db)):
    return schemas.Availability(available=not crud.phone_exists(db, phone))


@router.get("/{user_id}", response_model=schemas.UserRead)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = crud.get_user(db, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return user


@router.patch("/{user_id}", response_model=schemas.UserRead)
def update_user(
    user_id: int, payload: schemas.UserUpdate, db: Session = Depends(get_db)
):
    user = crud.get_user(db, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    if payload.user_phone and payload.user_phone != user.user_phone:
        if crud.phone_exists(db, payload.user_phone):
            raise HTTPException(status_code=409, detail="이미 사용 중인 전화번호입니다.")
    return crud.update_user(db, user, payload)
