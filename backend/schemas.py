from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


def to_camel(value: str) -> str:
    parts = value.split("_")
    return parts[0] + "".join(part.capitalize() for part in parts[1:])


class ApiModel(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel,
    )


class UserBase(ApiModel):
    user_name: str = Field(min_length=1, max_length=45)
    user_email: str = Field(min_length=1, max_length=45)
    user_phone: Optional[str] = Field(default=None, max_length=20)
    user_address: Optional[str] = Field(default=None, max_length=45)
    user_birth_date: Optional[date] = None


class UserCreate(UserBase):
    user_password: str = Field(min_length=1, max_length=255)


class UserUpdate(ApiModel):
    user_name: Optional[str] = Field(default=None, min_length=1, max_length=45)
    user_phone: Optional[str] = Field(default=None, max_length=20)
    user_address: Optional[str] = Field(default=None, max_length=45)
    user_birth_date: Optional[date] = None


class UserPasswordUpdate(ApiModel):
    current_password: str = Field(min_length=1, max_length=255)
    new_password: str = Field(min_length=1, max_length=255)


class UserLogin(ApiModel):
    user_email: str
    user_password: str


class UserAccountLookup(ApiModel):
    user_name: str = Field(min_length=1, max_length=45)
    user_phone: str = Field(min_length=1, max_length=20)


class UserAccountLookupRead(ApiModel):
    user_email: str


class UserRead(ApiModel):
    user_id: int
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    user_phone: Optional[str] = None
    user_address: Optional[str] = None
    user_birth_date: Optional[date] = None
    user_create_at: Optional[date] = None
    user_updated_at: Optional[date] = None


class Availability(ApiModel):
    available: bool


class ScheduleTypeBase(ApiModel):
    schedule_type_name: str = Field(min_length=1, max_length=45)
    schedule_type_color: str = Field(min_length=1, max_length=45)


class ScheduleTypeCreate(ScheduleTypeBase):
    pass


class ScheduleTypeRead(ApiModel):
    schedule_type_id: int
    schedule_type_name: Optional[str] = None
    schedule_type_color: Optional[str] = None
    schedule_type_create_at: Optional[datetime] = None


class ScheduleBase(ApiModel):
    user_id: int
    schedule_type_id: int
    schedule_title: str = Field(min_length=1, max_length=45)
    schedule_content: Optional[str] = Field(default=None, max_length=45)
    schedule_start_date: datetime
    schedule_end_date: datetime
    schedule_is_done: bool = False


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(ApiModel):
    schedule_type_id: Optional[int] = None
    schedule_title: Optional[str] = Field(default=None, min_length=1, max_length=45)
    schedule_content: Optional[str] = Field(default=None, max_length=45)
    schedule_start_date: Optional[datetime] = None
    schedule_end_date: Optional[datetime] = None
    schedule_is_done: Optional[bool] = None


class ScheduleRead(ApiModel):
    schedule_id: int
    user_id: Optional[int] = None
    schedule_type_id: Optional[int] = None
    schedule_title: Optional[str] = None
    schedule_content: Optional[str] = None
    schedule_start_date: Optional[datetime] = None
    schedule_end_date: Optional[datetime] = None
    schedule_is_done: bool = False
    schedule_created_at: Optional[datetime] = None
    schedule_updated_at: Optional[datetime] = None


class DiaryBase(ApiModel):
    user_id: int
    diary_date: datetime
    diary_title: str = Field(default="", max_length=45)
    diary_content: Optional[str] = Field(default=None, max_length=45)


class DiaryCreate(DiaryBase):
    pass


class DiaryUpdate(ApiModel):
    diary_date: Optional[datetime] = None
    diary_title: Optional[str] = Field(default=None, max_length=45)
    diary_content: Optional[str] = Field(default=None, max_length=45)


class DiaryRead(ApiModel):
    diary_id: int
    user_id: Optional[int] = None
    diary_date: Optional[datetime] = None
    diary_title: Optional[str] = None
    diary_content: Optional[str] = None
    diary_created_at: Optional[datetime] = None
    diary_updated_at: Optional[datetime] = None


class DiaryImageBase(ApiModel):
    diary_id: int
    diary_image_url: str = Field(min_length=1, max_length=45)
    diary_image_order: int = 0
    diary_image_is_representative: bool = False


class DiaryImageCreate(DiaryImageBase):
    pass


class DiaryImageRead(DiaryImageBase):
    diary_image_id: int
    diary_image_created_at: Optional[datetime] = None
