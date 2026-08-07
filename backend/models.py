from typing import Optional
from pydantic import BaseModel, Field


# ==========================
# Student Models
# ==========================

class StudentRegister(BaseModel):
    name: str = Field(..., min_length=2, json_schema_extra={"example": "Alex Smith"})
    reg_no: str = Field(..., min_length=3, json_schema_extra={"example": "REG12345"})
    college: str = Field(..., json_schema_extra={"example": "Engineering Campus"})
    phone: str = Field(..., min_length=10, max_length=15, json_schema_extra={"example": "9876543210"})
    password: str = Field(..., min_length=6, json_schema_extra={"example": "secret123"})
    
    # Bike details (Optional for passengers)
    has_bike: bool = False
    bike_model: Optional[str] = Field(None, json_schema_extra={"example": "Yamaha FZ"})
    bike_number: Optional[str] = Field(None, json_schema_extra={"example": "KA-01-AB-1234"})


class StudentLogin(BaseModel):
    reg_no: str
    password: str


# ==========================
# Ride Models
# ==========================

class RideCreate(BaseModel):
    from_place: str = Field(..., json_schema_extra={"example": "Campus Gate A"})
    to_place: str = Field(..., json_schema_extra={"example": "Metro Station"})
    ride_date: str = Field(..., json_schema_extra={"example": "2026-08-01"})
    ride_time: str = Field(..., json_schema_extra={"example": "17:30"})
    available_seat: int = Field(default=1, ge=1, le=4, json_schema_extra={"example": 1})
    helmet: bool = True
    message: Optional[str] = Field(None, json_schema_extra={"example": "Leaving on time, helmet available."})


class RideUpdate(BaseModel):
    from_place: Optional[str] = None
    to_place: Optional[str] = None
    ride_date: Optional[str] = None
    ride_time: Optional[str] = None
    available_seat: Optional[int] = Field(None, ge=0)
    helmet: Optional[bool] = None
    message: Optional[str] = None


# ==========================
# Booking Models
# ==========================

class BookingRequest(BaseModel):
    ride_id: int


class BookingDecision(BaseModel):
    request_id: int


# ==========================
# Token Models
# ==========================

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    student_id: Optional[int] = None
    reg_no: Optional[str] = None