from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from database import engine
from routers import diaries, images, schedules, users

app = FastAPI(
    title="Life Log API",
    version="1.0.0",
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
