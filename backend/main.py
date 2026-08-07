from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Database Initializer
from database import init_db

# Import All Routers
from auth import router as auth_router
from booking import router as booking_router
from ride import router as rides_router
from notification import router as notification_router
from chat import router as chat_router
from student import router as student_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Code executed on startup
    init_db()
    yield

app = FastAPI(
    title="Boro Rideshare API",
    description="Campus ridesharing platform for college students",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Frontend/Mobile Client Integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_router)
app.include_router(booking_router)
app.include_router(rides_router)
app.include_router(notification_router)
app.include_router(chat_router)
app.include_router(student_router)

@app.get("/", tags=["Health"])
def root():
    return {"status": "online", "message": "Welcome to Boro API"}