import sqlite3
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from database import get_db
from dependencies import get_current_student
from utils import verify_password, hash_password  # Using centralized password utils

router = APIRouter(
    prefix="/student",
    tags=["Student"]
)



# Pydantic Schemas

class ChangePasswordSchema(BaseModel):
    old_password: str = Field(..., min_length=6)
    new_password: str = Field(..., min_length=6)


class BikeUpdateSchema(BaseModel):
    bike_model: str = Field(..., json_schema_extra={"example": "Yamaha FZ"})
    bike_number: str = Field(..., json_schema_extra={"example": "KA-01-AB-1234"})


# My Profile


@router.get("/profile")
def my_profile(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        SELECT
            id, name, reg_no, college, phone, has_bike, bike_model, bike_number, created_at
        FROM students
        WHERE id = ?
        """,
        (student_id,)
    )

    student = cursor.fetchone()

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found."
        )

    return {
        "profile": {
            "id": student["id"],
            "name": student["name"],
            "reg_no": student["reg_no"],
            "college": student["college"],
            "phone": student["phone"],
            "has_bike": bool(student["has_bike"]),
            "bike_model": student["bike_model"],
            "bike_number": student["bike_number"],
            "created_at": student["created_at"]
        }
    }


# Update Bike Details

@router.put("/bike")
def update_bike(
    data: BikeUpdateSchema,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    cursor = db.cursor()
    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        UPDATE students
        SET
            has_bike = 1,
            bike_model = ?,
            bike_number = ?
        WHERE id = ?
        """,
        (data.bike_model, data.bike_number, student_id)
    )

    db.commit()

    return {"message": "Bike details updated successfully."}


# Change Password

@router.put("/change-password")
def change_password(
    data: ChangePasswordSchema,
    current_student: dict = Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute("SELECT password FROM students WHERE id = ?", (student_id,))
    student = cursor.fetchone()

    if not student or not verify_password(data.old_password, student["password"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect current password."
        )

    new_hashed_password = hash_password(data.new_password)
    cursor.execute(
        "UPDATE students SET password = ? WHERE id = ?",
        (new_hashed_password, student_id)
    )

    db.commit()

    return {"message": "Password updated successfully."}


# My Posted Rides

@router.get("/my-rides")
def my_posted_rides(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        SELECT id, from_place, to_place, ride_date, ride_time, available_seat, helmet, status
        FROM rides
        WHERE host_id = ?
        ORDER BY ride_date, ride_time
        """,
        (student_id,)
    )

    rows = cursor.fetchall()

    rides = [
        {
            "id": row["id"],
            "from_place": row["from_place"],
            "to_place": row["to_place"],
            "ride_date": row["ride_date"],
            "ride_time": row["ride_time"],
            "available_seat": row["available_seat"],
            "helmet": bool(row["helmet"]),
            "status": row["status"]
        }
        for row in rows
    ]

    return {"rides": rides}



# My Booking Requests

@router.get("/my-bookings")
def my_bookings(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        SELECT
            br.id AS request_id,
            r.from_place,
            r.to_place,
            r.ride_date,
            r.ride_time,
            br.status
        FROM booking_requests br
        JOIN rides r ON br.ride_id = r.id
        WHERE br.passenger_id = ?
        ORDER BY br.id DESC
        """,
        (student_id,)
    )

    rows = cursor.fetchall()

    bookings = [
        {
            "request_id": row["request_id"],
            "from_place": row["from_place"],
            "to_place": row["to_place"],
            "ride_date": row["ride_date"],
            "ride_time": row["ride_time"],
            "status": row["status"]
        }
        for row in rows
    ]

    return {"bookings": bookings}


# Delete My Account

@router.delete("/delete")
def delete_account(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute("DELETE FROM students WHERE id = ?", (student_id,))
    db.commit()

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found."
        )

    return {"message": "Account deleted successfully."}