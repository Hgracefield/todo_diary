from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


# =========================================================
# USER
# =========================================================
class User(Base):
    __tablename__ = "USERS"

    user_id: Mapped[int] = mapped_column(
        "USER_ID",
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    user_name: Mapped[str | None] = mapped_column(
        "USER_NAME",
        String(45),
        nullable=True,
    )

    user_password: Mapped[str | None] = mapped_column(
        "USER_PASSWORD_HASH",
        String(255),
        nullable=True,
    )

    user_phone: Mapped[str | None] = mapped_column(
        "USER_PHONE",
        String(20),
        nullable=True,
    )

    user_email: Mapped[str | None] = mapped_column(
        "USER_EMAIL",
        String(45),
        nullable=True,
    )

    user_address: Mapped[str | None] = mapped_column(
        "USER_ADDRESS",
        String(45),
        nullable=True,
    )

    user_birth_date: Mapped[date | None] = mapped_column(
        "USER_BIRTH_DATE",
        Date,
        nullable=True,
    )

    user_create_at: Mapped[date | None] = mapped_column(
        "USER_CREATE_AT",
        Date,
        nullable=True,
    )

    user_updated_at: Mapped[date | None] = mapped_column(
        "USER_UPDATED_AT",
        Date,
        nullable=True,
    )


# =========================================================
# SCHEDULE_TYPE
# =========================================================
class ScheduleType(Base):
    __tablename__ = "SCHEDULE_TYPE"

    schedule_type_id: Mapped[int] = mapped_column(
        "SCHEDULE_TYPE_ID",
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    schedule_type_color: Mapped[str | None] = mapped_column(
        "SCHEDULE_TYPE_COLOR",
        String(45),
        nullable=True,
    )

    schedule_type_name: Mapped[str | None] = mapped_column(
        "SCHEDULE_TYPE_NAME",
        String(45),
        nullable=True,
    )

    schedule_type_create_at: Mapped[datetime | None] = mapped_column(
        "SCHEDULE_TYPE_CREATED_AT",
        DateTime,
        nullable=True,
    )


# =========================================================
# SCHEDULE
# =========================================================
class Schedule(Base):
    __tablename__ = "SCHEDULE"

    schedule_id: Mapped[int] = mapped_column(
        "SCHEDULE_ID",
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    schedule_title: Mapped[str | None] = mapped_column(
        "SCHEDULE_TITLE",
        String(45),
        nullable=True,
    )

    schedule_end_date: Mapped[datetime | None] = mapped_column(
        "SCHEDULE_END_DATE",
        DateTime,
        nullable=True,
    )

    schedule_start_date: Mapped[datetime | None] = mapped_column(
        "SCHEDULE_START_DATE",
        DateTime,
        nullable=True,
    )

    schedule_content: Mapped[str | None] = mapped_column(
        "SCHEDULE_CONTENT",
        String(45),
        nullable=True,
    )

    schedule_updated_at: Mapped[datetime | None] = mapped_column(
        "SCHEDULE_UPDATED_AT",
        DateTime,
        nullable=True,
    )

    schedule_created_at: Mapped[datetime | None] = mapped_column(
        "SCHEDULE_CREATED_AT",
        DateTime,
        nullable=True,
    )

    # 현재 EER에 있는 첫 번째 SCHEDULE_TYPE 외래키
    schedule_set_schedule_type_id: Mapped[int | None] = mapped_column(
        "SCHEDULE_SET_SCHEDULE_TYPE_SCHEDULE_TYPE_ID",
        Integer,
        ForeignKey("SCHEDULE_TYPE.SCHEDULE_TYPE_ID"),
        nullable=True,
    )

    # 현재 EER에 있는 두 번째 SCHEDULE_TYPE 외래키
    schedule_type_id: Mapped[int | None] = mapped_column(
        "SCHEDULE_TYPE_SCHEDULE_TYPE_ID",
        Integer,
        ForeignKey("SCHEDULE_TYPE.SCHEDULE_TYPE_ID"),
        nullable=True,
    )

    user_id: Mapped[int | None] = mapped_column(
        "USER_USER_ID",
        Integer,
        ForeignKey("USERS.USER_ID"),
        nullable=True,
    )


# =========================================================
# DIARY_IMAGE
# =========================================================
class DiaryImage(Base):
    __tablename__ = "DIARY_IMAGE"

    diary_image_id: Mapped[int] = mapped_column(
        "DIARY_IMAGE_ID",
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    diary_image_order: Mapped[int | None] = mapped_column(
        "DIARY_IMAGE_ORDER",
        Integer,
        nullable=True,
    )

    diary_image_url: Mapped[str | None] = mapped_column(
        "DIARY_IMAGE_URL",
        String(45),
        nullable=True,
    )

    diary_image_created_at: Mapped[datetime | None] = mapped_column(
        "DIARY_IMAGE_CREATED_AT",
        DateTime,
        nullable=True,
    )

    diary_image_is_representative: Mapped[int | None] = mapped_column(
        "DIARY_IMAGE_IS_REPRESENTATIVE",
        Integer,
        nullable=True,
    )


# =========================================================
# DIARY
# =========================================================
class Diary(Base):
    __tablename__ = "DIARY"

    diary_id: Mapped[int] = mapped_column(
        "DIARY_ID",
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    diary_date: Mapped[datetime | None] = mapped_column(
        "DIARY_DATE",
        DateTime,
        nullable=True,
    )

    diary_content: Mapped[str | None] = mapped_column(
        "DIARY_CONTENT",
        String(45),
        nullable=True,
    )

    diary_created_at: Mapped[datetime | None] = mapped_column(
        "DIARY_CREATED_AT",
        DateTime,
        nullable=True,
    )

    diary_updated_at: Mapped[datetime | None] = mapped_column(
        "DIARY_UPDATED_AT",
        DateTime,
        nullable=True,
    )

    diary_title: Mapped[str | None] = mapped_column(
        "DIARY_TITLE",
        String(45),
        nullable=True,
    )

    user_id: Mapped[int | None] = mapped_column(
        "USER_USER_ID",
        Integer,
        ForeignKey("USERS.USER_ID"),
        nullable=True,
    )

    diary_image_id: Mapped[int | None] = mapped_column(
        "DIARY_IMAGE_DIARY_IMAGE_ID",
        Integer,
        ForeignKey("DIARY_IMAGE.DIARY_IMAGE_ID"),
        nullable=True,
    )
