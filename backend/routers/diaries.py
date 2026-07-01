from __future__ import annotations

from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

import crud
import schemas
from database import get_db

router = APIRouter(prefix="/diaries", tags=["diaries"])


@router.get("", response_model=list[schemas.DiaryRead])
def get_diaries(
    user_id: int = Query(alias="userId"),
    start_date: Optional[date] = Query(default=None, alias="startDate"),
    end_date: Optional[date] = Query(default=None, alias="endDate"),
    db: Session = Depends(get_db),
):
    return crud.list_diaries(db, user_id, start_date, end_date)


@router.get("/by-date", response_model=schemas.DiaryRead)
def get_diary_by_date(
    user_id: int = Query(alias="userId"),
    diary_date: date = Query(alias="date"),
    db: Session = Depends(get_db),
):
    item = crud.get_diary_by_date(db, user_id, diary_date)
    if item is None:
        raise HTTPException(status_code=404, detail="일기를 찾을 수 없습니다.")
    return item


@router.post(
    "",
    response_model=schemas.DiaryRead,
    status_code=status.HTTP_201_CREATED,
)
def create_diary(payload: schemas.DiaryCreate, db: Session = Depends(get_db)):
    existing = crud.get_diary_by_date(
        db, payload.user_id, payload.diary_date.date()
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="해당 날짜의 일기가 이미 존재합니다.")
    return crud.create_diary(db, payload)


@router.patch("/{diary_id}", response_model=schemas.DiaryRead)
def update_diary(
    diary_id: int, payload: schemas.DiaryUpdate, db: Session = Depends(get_db)
):
    item = crud.get_diary(db, diary_id)
    if item is None:
        raise HTTPException(status_code=404, detail="일기를 찾을 수 없습니다.")
    return crud.update_diary(db, item, payload)


@router.delete("/{diary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_diary(diary_id: int, db: Session = Depends(get_db)):
    item = crud.get_diary(db, diary_id)
    if item is None:
        raise HTTPException(status_code=404, detail="일기를 찾을 수 없습니다.")
    crud.delete_instance(db, item)
