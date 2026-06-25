from datetime import date, datetime

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
    user_phone: str | None = Field(default=None, max_length=20)
    user_address: str | None = Field(default=None, max_length=45)
    user_birth_date: date | None = None


class UserCreate(UserBase):
    user_password: str = Field(min_length=1, max_length=255)


class UserUpdate(ApiModel):
    user_name: str | None = Field(default=None, min_length=1, max_length=45)
    user_password: str | None = Field(default=None, min_length=1, max_length=255)
    user_phone: str | None = Field(default=None, max_length=20)
    user_address: str | None = Field(default=None, max_length=45)
    user_birth_date: date | None = None


class UserLogin(ApiModel):
    user_email: str
    user_password: str


class UserRead(ApiModel):
    user_id: int
    user_name: str | None = None
    user_email: str | None = None
    user_phone: str | None = None
    user_address: str | None = None
    user_birth_date: date | None = None
    user_create_at: date | None = None
    user_updated_at: date | None = None


class Availability(ApiModel):
    available: bool


class ScheduleTypeBase(ApiModel):
    schedule_type_name: str = Field(min_length=1, max_length=45)
    schedule_type_color: str = Field(min_length=1, max_length=45)


class ScheduleTypeCreate(ScheduleTypeBase):
    pass


class ScheduleTypeRead(ApiModel):
    schedule_type_id: int
    schedule_type_name: str | None = None
    schedule_type_color: str | None = None
    schedule_type_create_at: datetime | None = None


class ScheduleBase(ApiModel):
    user_id: int
    schedule_type_id: int
    schedule_title: str = Field(min_length=1, max_length=45)
    schedule_content: str | None = Field(default=None, max_length=45)
    schedule_start_date: datetime
    schedule_end_date: datetime


class ScheduleCreate(ScheduleBase):
    pass


class ScheduleUpdate(ApiModel):
    schedule_type_id: int | None = None
    schedule_title: str | None = Field(default=None, min_length=1, max_length=45)
    schedule_content: str | None = Field(default=None, max_length=45)
    schedule_start_date: datetime | None = None
    schedule_end_date: datetime | None = None


class ScheduleRead(ApiModel):
    schedule_id: int
    user_id: int | None = None
    schedule_type_id: int | None = None
    schedule_title: str | None = None
    schedule_content: str | None = None
    schedule_start_date: datetime | None = None
    schedule_end_date: datetime | None = None
    schedule_created_at: datetime | None = None
    schedule_updated_at: datetime | None = None


class DiaryBase(ApiModel):
    user_id: int
    diary_date: datetime
    diary_title: str = Field(default="", max_length=45)
    diary_content: str | None = Field(default=None, max_length=45)


class DiaryCreate(DiaryBase):
    pass


class DiaryUpdate(ApiModel):
    diary_date: datetime | None = None
    diary_title: str | None = Field(default=None, max_length=45)
    diary_content: str | None = Field(default=None, max_length=45)


class DiaryRead(ApiModel):
    diary_id: int
    user_id: int | None = None
    diary_date: datetime | None = None
    diary_title: str | None = None
    diary_content: str | None = None
    diary_created_at: datetime | None = None
    diary_updated_at: datetime | None = None


class DiaryImageBase(ApiModel):
    diary_id: int
    diary_image_url: str = Field(min_length=1, max_length=45)
    diary_image_order: int = 0
    diary_image_is_representative: bool = False


class DiaryImageCreate(DiaryImageBase):
    pass


class DiaryImageRead(DiaryImageBase):
    diary_image_id: int
    diary_image_created_at: datetime | None = None
