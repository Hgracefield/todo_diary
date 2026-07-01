from __future__ import annotations

from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

import crud
import schemas
from database import get_db

router = APIRouter(tags=["schedules"])


@router.get("/schedule-types", response_model=list[schemas.ScheduleTypeRead])
def get_schedule_types(db: Session = Depends(get_db)):
    return crud.list_schedule_types(db)


@router.post(
    "/schedule-types",
    response_model=schemas.ScheduleTypeRead,
    status_code=status.HTTP_201_CREATED,
)
def create_schedule_type(
    payload: schemas.ScheduleTypeCreate, db: Session = Depends(get_db)
):
    return crud.create_schedule_type(db, payload)


@router.get("/schedules", response_model=list[schemas.ScheduleRead])
def get_schedules(
    user_id: int = Query(alias="userId"),
    start_date: Optional[date] = Query(default=None, alias="startDate"),
    end_date: Optional[date] = Query(default=None, alias="endDate"),
    db: Session = Depends(get_db),
):
    return crud.list_schedules(db, user_id, start_date, end_date)


@router.post(
    "/schedules",
    response_model=schemas.ScheduleRead,
    status_code=status.HTTP_201_CREATED,
)
def create_schedule(
    payload: schemas.ScheduleCreate, db: Session = Depends(get_db)
):
    return crud.create_schedule(db, payload)


@router.patch("/schedules/{schedule_id}", response_model=schemas.ScheduleRead)
def update_schedule(
    schedule_id: int,
    payload: schemas.ScheduleUpdate,
    db: Session = Depends(get_db),
):
    item = crud.get_schedule(db, schedule_id)
    if item is None:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없습니다.")
    return crud.update_schedule(db, item, payload)


@router.delete("/schedules/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_schedule(schedule_id: int, db: Session = Depends(get_db)):
    item = crud.get_schedule(db, schedule_id)
    if item is None:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없습니다.")
    crud.delete_instance(db, item)
