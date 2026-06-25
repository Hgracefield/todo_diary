from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

import crud
import models
import schemas
from database import get_db

router = APIRouter(prefix="/diaries/{diary_id}/images", tags=["diary-images"])


@router.get("", response_model=list[schemas.DiaryImageRead])
def get_images(diary_id: int, db: Session = Depends(get_db)):
    diary = crud.get_diary(db, diary_id)
    if diary is None:
        raise HTTPException(status_code=404, detail="일기를 찾을 수 없습니다.")
    images = crud.list_diary_images(db, diary)
    return [
        schemas.DiaryImageRead(
            diary_id=diary_id,
            diary_image_id=image.diary_image_id,
            diary_image_url=image.diary_image_url or "",
            diary_image_order=image.diary_image_order or 0,
            diary_image_is_representative=bool(
                image.diary_image_is_representative
            ),
            diary_image_created_at=image.diary_image_created_at,
        )
        for image in images
    ]


@router.post(
    "",
    response_model=schemas.DiaryImageRead,
    status_code=status.HTTP_201_CREATED,
)
def create_image(
    diary_id: int,
    payload: schemas.DiaryImageCreate,
    db: Session = Depends(get_db),
):
    diary = crud.get_diary(db, diary_id)
    if diary is None:
        raise HTTPException(status_code=404, detail="일기를 찾을 수 없습니다.")
    if payload.diary_id != diary_id:
        raise HTTPException(status_code=400, detail="일기 ID가 일치하지 않습니다.")
    image = crud.create_diary_image(db, diary, payload)
    return schemas.DiaryImageRead(
        diary_id=diary_id,
        diary_image_id=image.diary_image_id,
        diary_image_url=image.diary_image_url or "",
        diary_image_order=image.diary_image_order or 0,
        diary_image_is_representative=bool(
            image.diary_image_is_representative
        ),
        diary_image_created_at=image.diary_image_created_at,
    )


@router.delete("/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_image(diary_id: int, image_id: int, db: Session = Depends(get_db)):
    diary = crud.get_diary(db, diary_id)
    if diary is None or diary.diary_image_id != image_id:
        raise HTTPException(status_code=404, detail="이미지를 찾을 수 없습니다.")
    image = db.get(models.DiaryImage, image_id)
    diary.diary_image_id = None
    if image is not None:
        db.delete(image)
    db.commit()
