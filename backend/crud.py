import hashlib
import hmac
import secrets
from datetime import date, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

import models
import schemas


def _apply_changes(instance, changes: dict) -> None:
    for key, value in changes.items():
        setattr(instance, key, value)


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), bytes.fromhex(salt), 210_000
    ).hex()
    return f"pbkdf2_sha256$210000${salt}${digest}"


def verify_password(password: str, encoded: str | None) -> bool:
    if not encoded:
        return False
    if not encoded.startswith("pbkdf2_sha256$"):
        return hmac.compare_digest(password, encoded)
    try:
        _, iterations, salt, expected = encoded.split("$", 3)
        actual = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode(),
            bytes.fromhex(salt),
            int(iterations),
        ).hex()
        return hmac.compare_digest(actual, expected)
    except (TypeError, ValueError):
        return False


def create_user(db: Session, payload: schemas.UserCreate) -> models.User:
    now = date.today()
    values = payload.model_dump()
    values["user_password"] = hash_password(values["user_password"])
    user = models.User(
        **values,
        user_create_at=now,
        user_updated_at=now,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_user(db: Session, user_id: int) -> models.User | None:
    return db.get(models.User, user_id)


def get_user_by_email(db: Session, email: str) -> models.User | None:
    return db.scalar(select(models.User).where(models.User.user_email == email))


def email_exists(db: Session, email: str) -> bool:
    return get_user_by_email(db, email) is not None


def phone_exists(db: Session, phone: str) -> bool:
    return db.scalar(
        select(models.User.user_id).where(models.User.user_phone == phone)
    ) is not None


def update_user(
    db: Session, user: models.User, payload: schemas.UserUpdate
) -> models.User:
    changes = payload.model_dump(exclude_unset=True)
    if changes.get("user_password"):
        changes["user_password"] = hash_password(changes["user_password"])
    changes["user_updated_at"] = date.today()
    _apply_changes(user, changes)
    db.commit()
    db.refresh(user)
    return user


def list_schedule_types(db: Session) -> list[models.ScheduleType]:
    return list(
        db.scalars(
            select(models.ScheduleType).order_by(
                models.ScheduleType.schedule_type_id
            )
        ).all()
    )


def create_schedule_type(
    db: Session, payload: schemas.ScheduleTypeCreate
) -> models.ScheduleType:
    item = models.ScheduleType(
        **payload.model_dump(),
        schedule_type_create_at=datetime.now(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def list_schedules(
    db: Session,
    user_id: int,
    start_date: date | None = None,
    end_date: date | None = None,
) -> list[models.Schedule]:
    statement = select(models.Schedule).where(models.Schedule.user_id == user_id)
    if start_date is not None:
        statement = statement.where(
            models.Schedule.schedule_start_date >= datetime.combine(
                start_date, time.min
            )
        )
    if end_date is not None:
        statement = statement.where(
            models.Schedule.schedule_start_date
            < datetime.combine(end_date + timedelta(days=1), time.min)
        )
    statement = statement.order_by(
        models.Schedule.schedule_start_date,
        models.Schedule.schedule_id.desc(),
    )
    return list(db.scalars(statement).all())


def create_schedule(
    db: Session, payload: schemas.ScheduleCreate
) -> models.Schedule:
    schedule_type = db.get(models.ScheduleType, payload.schedule_type_id)
    if schedule_type is None:
        defaults = {
            1: ("기본", "green"),
            2: ("중요", "orange"),
            3: ("기타", "pink"),
        }
        name, color = defaults.get(
            payload.schedule_type_id,
            (f"분류 {payload.schedule_type_id}", "green"),
        )
        schedule_type = models.ScheduleType(
            schedule_type_id=payload.schedule_type_id,
            schedule_type_name=name,
            schedule_type_color=color,
            schedule_type_create_at=datetime.now(),
        )
        db.add(schedule_type)
        db.flush()

    now = datetime.now()
    item = models.Schedule(
        **payload.model_dump(),
        schedule_set_schedule_type_id=payload.schedule_type_id,
        schedule_created_at=now,
        schedule_updated_at=now,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def get_schedule(db: Session, schedule_id: int) -> models.Schedule | None:
    return db.get(models.Schedule, schedule_id)


def update_schedule(
    db: Session, item: models.Schedule, payload: schemas.ScheduleUpdate
) -> models.Schedule:
    changes = payload.model_dump(exclude_unset=True)
    if "schedule_type_id" in changes:
        changes["schedule_set_schedule_type_id"] = changes["schedule_type_id"]
    changes["schedule_updated_at"] = datetime.now()
    _apply_changes(item, changes)
    db.commit()
    db.refresh(item)
    return item


def delete_instance(db: Session, item) -> None:
    db.delete(item)
    db.commit()


def list_diaries(
    db: Session,
    user_id: int,
    start_date: date | None = None,
    end_date: date | None = None,
) -> list[models.Diary]:
    statement = select(models.Diary).where(models.Diary.user_id == user_id)
    if start_date is not None:
        statement = statement.where(
            models.Diary.diary_date >= datetime.combine(start_date, time.min)
        )
    if end_date is not None:
        statement = statement.where(
            models.Diary.diary_date
            < datetime.combine(end_date + timedelta(days=1), time.min)
        )
    statement = statement.order_by(models.Diary.diary_date.desc())
    return list(db.scalars(statement).all())


def get_diary(db: Session, diary_id: int) -> models.Diary | None:
    return db.get(models.Diary, diary_id)


def get_diary_by_date(
    db: Session, user_id: int, diary_date: date
) -> models.Diary | None:
    start = datetime.combine(diary_date, time.min)
    end = start + timedelta(days=1)
    return db.scalar(
        select(models.Diary).where(
            models.Diary.user_id == user_id,
            models.Diary.diary_date >= start,
            models.Diary.diary_date < end,
        )
    )


def create_diary(db: Session, payload: schemas.DiaryCreate) -> models.Diary:
    now = datetime.now()
    item = models.Diary(
        **payload.model_dump(),
        diary_created_at=now,
        diary_updated_at=now,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_diary(
    db: Session, item: models.Diary, payload: schemas.DiaryUpdate
) -> models.Diary:
    changes = payload.model_dump(exclude_unset=True)
    changes["diary_updated_at"] = datetime.now()
    _apply_changes(item, changes)
    db.commit()
    db.refresh(item)
    return item


def list_diary_images(db: Session, diary: models.Diary) -> list[models.DiaryImage]:
    if diary.diary_image_id is None:
        return []
    image = db.get(models.DiaryImage, diary.diary_image_id)
    return [] if image is None else [image]


def create_diary_image(
    db: Session, diary: models.Diary, payload: schemas.DiaryImageCreate
) -> models.DiaryImage:
    image = models.DiaryImage(
        diary_image_url=payload.diary_image_url,
        diary_image_order=payload.diary_image_order,
        diary_image_is_representative=int(
            payload.diary_image_is_representative
        ),
        diary_image_created_at=datetime.now(),
    )
    db.add(image)
    db.flush()
    diary.diary_image_id = image.diary_image_id
    db.commit()
    db.refresh(image)
    return image
