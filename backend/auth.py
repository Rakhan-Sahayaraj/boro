import sqlite3
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field

from database import get_db
from utils import hash_password, verify_password, create_access_token, verify_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# --- SCHEMAS ---
class StudentRegister(BaseModel):
    name: str = Field(..., json_schema_extra={"example": "John Doe"})
    reg_no: str = Field(..., json_schema_extra={"example": "REG12345"})
    college: str = Field(..., json_schema_extra={"example": "Engineering College"})
    phone: str = Field(..., json_schema_extra={"example": "1234567890"})
    password: str = Field(..., json_schema_extra={"example": "securepassword"})
    has_bike: bool = False
    bike_model: Optional[str] = Field(None, json_schema_extra={"example": "Yamaha R15"})
    bike_number: Optional[str] = Field(None, json_schema_extra={"example": "KA01MN1234"})

class BikeUpdateSchema(BaseModel):
    has_bike: bool = True
    bike_model: str = Field(..., json_schema_extra={"example": "KTM Duke"})
    bike_number: str = Field(..., json_schema_extra={"example": "KA01MN1234"})

router = APIRouter(prefix="/auth", tags=["Authentication"])

# --- CURRENT USER DEPENDENCY ---
def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload  # Contains {"student_id": ..., "reg_no": ...}

# --- GET LOGGED-IN USER PROFILE ---
@router.get("/me")
def get_me(
    current_user: dict = Depends(get_current_user),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute(
        "SELECT id, name, reg_no, college, phone, has_bike, bike_model, bike_number FROM students WHERE id = ?",
        (current_user["student_id"],)
    )
    user = cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return {
        "id": user["id"],
        "name": user["name"],
        "reg_no": user["reg_no"],
        "college": user["college"],
        "phone": user["phone"],
        "has_bike": bool(user["has_bike"]),
        "bike_model": user["bike_model"],
        "bike_number": user["bike_number"],
    }

# --- REGISTER ---
@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(
    student: StudentRegister,
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if student.has_bike:
        if not student.bike_model or not student.bike_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bike model and bike number are required if you have a bike."
            )
    else:
        student.bike_model = None
        student.bike_number = None

    cursor.execute("SELECT id FROM students WHERE reg_no = ?", (student.reg_no,))
    if cursor.fetchone():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration number already exists."
        )

    cursor.execute("SELECT id FROM students WHERE phone = ?", (student.phone,))
    if cursor.fetchone():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already exists."
        )

    hashed_pwd = hash_password(student.password)

    cursor.execute(
        """
        INSERT INTO students (
            name, reg_no, college, phone, password, has_bike, bike_model, bike_number, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            student.name,
            student.reg_no,
            student.college,
            student.phone,
            hashed_pwd,
            1 if student.has_bike else 0,
            student.bike_model,
            student.bike_number,
            datetime.now(timezone.utc).isoformat()
        )
    )

    db.commit()
    return {"message": "Registration Successful"}

# --- LOGIN ---
@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute(
        "SELECT id, password, has_bike, bike_model, bike_number FROM students WHERE reg_no = ?",
        (form_data.username,)
    )
    user = cursor.fetchone()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found."
        )

    student_id = user["id"]
    stored_password = user["password"]
    has_bike = bool(user["has_bike"])
    bike_model = user["bike_model"]
    bike_number = user["bike_number"]

    if not verify_password(form_data.password, stored_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password.",
            headers={"WWW-Authenticate": "Bearer"}
        )

    access_token = create_access_token(
        {
            "student_id": student_id,
            "reg_no": form_data.username,
            "has_bike": has_bike,
            "bike_model": bike_model,
            "bike_number": bike_number
        }
    )

    return {
        "message": "Login Successful",
        "access_token": access_token,
        "token_type": "bearer",
        "has_bike": has_bike,
        "bike_model": bike_model,
        "bike_number": bike_number
    }

# --- UPDATE BIKE DETAILS ---
@router.put("/update-bike")
def update_bike(
    data: BikeUpdateSchema,
    current_user: dict = Depends(get_current_user),
    db: sqlite3.Connection = Depends(get_db)
):
    student_id = current_user.get("student_id")
    
    cursor = db.cursor()
    cursor.execute(
        """
        UPDATE students
        SET has_bike = 1, bike_model = ?, bike_number = ?
        WHERE id = ?
        """,
        (data.bike_model.strip(), data.bike_number.strip().upper(), student_id)
    )
    
    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student account not found."
        )

    db.commit()
    return {"message": "Bike details updated successfully"}