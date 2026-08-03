import sqlite3
from fastapi import APIRouter, Depends, HTTPException, status
from dependencies import get_current_student
from models import RideCreate, RideUpdate
from database import get_db

router = APIRouter(prefix="/ride", tags=["Ride"])

def ride_to_dict(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "host_id": row["host_id"],
        "from_place": row["from_place"],
        "to_place": row["to_place"],
        "ride_date": row["ride_date"],
        "ride_time": row["ride_time"],
        "helmet": bool(row["helmet"]),
        "status": row["status"]
    }

# ==========================
# Post Ride (Strictly 1 Pillion for 2-Wheelers)
# ==========================
@router.post("/post", status_code=status.HTTP_201_CREATED)
def post_ride(
    ride: RideCreate,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    host_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute("SELECT has_bike FROM students WHERE id = ?", (host_id,))
    student = cursor.fetchone()
    if not student or not student["has_bike"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students with a registered bike can post rides."
        )

    # Hardcoded available_seat = 1 for two-wheelers
    cursor.execute(
        """
        INSERT INTO rides (
            host_id, from_place, to_place, ride_date, ride_time, helmet, available_seat, status
        ) VALUES (?, ?, ?, ?, ?, ?, 1, 'Available')
        """,
        (
            host_id,
            ride.from_place,
            ride.to_place,
            ride.ride_date,
            ride.ride_time,
            int(ride.helmet)
        )
    )

    db.commit()
    return {"message": "Ride posted successfully.", "ride_id": cursor.lastrowid}

# ==========================
# Cancel Active Rides & Requests on Logout
# ==========================
@router.post("/logout-cleanup")
def logout_cleanup(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    cursor = db.cursor()
    student_id = current_student.get("id") or current_student.get("student_id")

    # 1. Delete all active/available rides posted by this Host
    cursor.execute("DELETE FROM rides WHERE host_id = ? AND status = 'Available'", (student_id,))

    # 2. Cancel all pending booking requests created by this Passenger/Pillion
    cursor.execute("UPDATE booking_requests SET status = 'CANCELLED' WHERE passenger_id = ? AND status = 'PENDING'", (student_id,))

    db.commit()
    return {"message": "Active rides and pending requests cancelled on logout."}

# ==========================
# Get All Available Rides (Passenger View)
# ==========================
@router.get("/all")
def get_rides(db: sqlite3.Connection = Depends(get_db)):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    cursor.execute("""
        SELECT id, host_id, from_place, to_place, ride_date, ride_time, helmet, status
        FROM rides
        WHERE status = 'Available'
        ORDER BY ride_date, ride_time
    """)

    return [ride_to_dict(row) for row in cursor.fetchall()]

# ==========================
# My Posted Rides (Host View)
# ==========================
@router.get("/my")
def my_rides(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        """
        SELECT id, host_id, from_place, to_place, ride_date, ride_time, helmet, status
        FROM rides
        WHERE host_id = ?
        ORDER BY ride_date, ride_time
        """,
        (student_id,)
    )

    return [ride_to_dict(row) for row in cursor.fetchall()]

# ==========================
# Update Ride
# ==========================
@router.put("/{ride_id}")
def update_ride(
    ride_id: int,
    ride: RideUpdate,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    student_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute("SELECT * FROM rides WHERE id = ? AND host_id = ?", (ride_id, student_id))
    existing_ride = cursor.fetchone()

    if not existing_ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or you are not the owner."
        )

    from_place = ride.from_place if ride.from_place is not None else existing_ride["from_place"]
    to_place = ride.to_place if ride.to_place is not None else existing_ride["to_place"]
    ride_date = ride.ride_date if ride.ride_date is not None else existing_ride["ride_date"]
    ride_time = ride.ride_time if ride.ride_time is not None else existing_ride["ride_time"]
    helmet = int(ride.helmet) if ride.helmet is not None else existing_ride["helmet"]

    cursor.execute(
        """
        UPDATE rides
        SET from_place = ?, to_place = ?, ride_date = ?, ride_time = ?, helmet = ?
        WHERE id = ? AND host_id = ?
        """,
        (from_place, to_place, ride_date, ride_time, helmet, ride_id, student_id)
    )

    db.commit()
    return {"message": "Ride updated successfully."}

# ==========================
# Delete Ride
# ==========================
@router.delete("/{ride_id}")
def delete_ride(
    ride_id: int,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    student_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute("DELETE FROM rides WHERE id = ? AND host_id = ?", (ride_id, student_id))
    db.commit()

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found or you are not the owner."
        )

    return {"message": "Ride deleted successfully."}