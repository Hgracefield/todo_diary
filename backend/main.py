from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from database import engine
from routers import diaries, images, schedules, users


def migrate_schedule_done_column():
    with engine.begin() as connection:
        db_name = connection.exec_driver_sql("SELECT DATABASE()").scalar()
        exists = connection.execute(
            text(
                """
                SELECT COUNT(*)
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = :db_name
                  AND TABLE_NAME = 'SCHEDULE'
                  AND COLUMN_NAME = 'SCHEDULE_IS_DONE'
                """
            ),
            {"db_name": db_name},
        ).scalar()

        if not exists:
            connection.exec_driver_sql(
                "ALTER TABLE SCHEDULE "
                "ADD COLUMN SCHEDULE_IS_DONE BOOLEAN NOT NULL DEFAULT FALSE"
            )


@asynccontextmanager
async def lifespan(app: FastAPI):
    migrate_schedule_done_column()
    yield


app = FastAPI(
    title="Life Log API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/api")
app.include_router(schedules.router, prefix="/api")
app.include_router(diaries.router, prefix="/api")
app.include_router(images.router, prefix="/api")


@app.get("/")
def root():
    return {
        "message": "Life Log API 서버가 실행 중입니다."
    }


@app.get("/db-test")
def database_test():
    try:
        with engine.connect() as connection:
            connection.exec_driver_sql("SELECT 1")

        return {
            "connected": True,
            "message": "MySQL 연결에 성공했습니다.",
        }

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )
