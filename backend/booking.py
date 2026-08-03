import sqlite3
from fastapi import APIRouter, Depends, HTTPException, status
from dependencies import get_current_student
from models import BookingRequest
from database import get_db

router = APIRouter(prefix="/booking", tags=["Booking"])

def request_to_dict(row):
    return {
        "id": row["id"],
        "ride_id": row["ride_id"],
        "passenger_id": row["passenger_id"],
        "status": row["status"]
    }

@router.post("/request", status_code=status.HTTP_201_CREATED)
def request_ride(
    booking: BookingRequest,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    passenger_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        "SELECT host_id, available_seat, status FROM rides WHERE id = ?",
        (booking.ride_id,)
    )
    ride = cursor.fetchone()

    if ride is None:
        raise HTTPException(status_code=404, detail="Ride not found.")

    host_id = ride["host_id"]
    available_seat = ride["available_seat"]
    ride_status = ride["status"]

    if host_id == passenger_id:
        raise HTTPException(status_code=400, detail="You cannot book your own ride.")

    if available_seat <= 0 or ride_status != "Available":
        raise HTTPException(status_code=400, detail="Ride is not available.")

    cursor.execute(
        "SELECT id FROM booking_requests WHERE ride_id = ? AND passenger_id = ? AND status = 'Pending'",
        (booking.ride_id, passenger_id)
    )
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="Request already sent.")

    cursor.execute(
        "INSERT INTO booking_requests (ride_id, passenger_id, status) VALUES (?, ?, 'Pending')",
        (booking.ride_id, passenger_id)
    )

    cursor.execute(
        "INSERT INTO notifications (student_id, title, message) VALUES (?, ?, ?)",
        (host_id, "New Ride Request", "A student has requested to join your ride.")
    )

    db.commit()
    return {"message": "Ride request sent successfully."}

@router.get("/my-requests")
def my_requests(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    passenger_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        "SELECT id, ride_id, passenger_id, status FROM booking_requests WHERE passenger_id = ?",
        (passenger_id,)
    )
    return [request_to_dict(row) for row in cursor.fetchall()]

@router.get("/ride-requests")
def ride_requests(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    host_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        """
        SELECT br.id, br.ride_id, br.passenger_id, br.status
        FROM booking_requests br
        JOIN rides r ON br.ride_id = r.id
        WHERE r.host_id = ? AND br.status = 'Pending'
        """,
        (host_id,)
    )
    return [request_to_dict(row) for row in cursor.fetchall()]

@router.put("/accept/{request_id}")
def accept_booking(
    request_id: int,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    host_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        """
        SELECT br.id, br.ride_id, br.passenger_id, br.status, r.host_id, r.available_seat
        FROM booking_requests br
        JOIN rides r ON br.ride_id = r.id
        WHERE br.id = ?
        """,
        (request_id,)
    )
    req = cursor.fetchone()

    if not req:
        raise HTTPException(status_code=404, detail="Request not found.")

    if req["host_id"] != host_id:
        raise HTTPException(status_code=403, detail="Unauthorized to accept this request.")

    if req["status"] != "Pending":
        raise HTTPException(status_code=400, detail=f"Request is already {req['status'].lower()}.")

    new_seats = max(0, req["available_seat"] - 1)
    new_status = "Full" if new_seats == 0 else "Available"

    cursor.execute("UPDATE booking_requests SET status = 'Accepted' WHERE id = ?", (request_id,))

    cursor.execute(
        "INSERT INTO confirmed_bookings (ride_id, host_id, passenger_id) VALUES (?, ?, ?)",
        (req["ride_id"], host_id, req["passenger_id"])
    )

    cursor.execute(
        "UPDATE rides SET available_seat = ?, status = ? WHERE id = ?",
        (new_seats, new_status, req["ride_id"])
    )

    if new_seats == 0:
        cursor.execute(
            "UPDATE booking_requests SET status = 'Rejected' WHERE ride_id = ? AND id != ? AND status = 'Pending'",
            (req["ride_id"], request_id)
        )

    cursor.execute(
        "INSERT INTO notifications (student_id, title, message) VALUES (?, ?, ?)",
        (req["passenger_id"], "Booking Confirmed", "Your ride request has been accepted by the host!")
    )

    db.commit()
    return {"message": "Booking accepted successfully."}

@router.put("/reject/{request_id}")
def reject_booking(
    request_id: int,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    host_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        """
        SELECT br.id, br.passenger_id, r.host_id
        FROM booking_requests br
        JOIN rides r ON br.ride_id = r.id
        WHERE br.id = ?
        """,
        (request_id,)
    )
    req = cursor.fetchone()

    if not req or req["host_id"] != host_id:
        raise HTTPException(status_code=404, detail="Request not found or unauthorized.")

    cursor.execute("UPDATE booking_requests SET status = 'Rejected' WHERE id = ?", (request_id,))

    cursor.execute(
        "INSERT INTO notifications (student_id, title, message) VALUES (?, ?, ?)",
        (req["passenger_id"], "Booking Declined", "Your ride request was declined by the host.")
    )

    db.commit()
    return {"message": "Booking rejected successfully."}

@router.put("/cancel/{request_id}")
def cancel_booking(
    request_id: int,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("id") or current_student.get("student_id")

    cursor.execute(
        """
        SELECT br.id, br.ride_id, br.passenger_id, br.status, r.host_id, r.from_place, r.to_place, r.available_seat
        FROM booking_requests br
        JOIN rides r ON br.ride_id = r.id
        WHERE br.id = ?
        """,
        (request_id,)
    )
    req = cursor.fetchone()

    if not req:
        raise HTTPException(status_code=404, detail="Booking request not found.")

    is_passenger = (req["passenger_id"] == student_id)
    is_host = (req["host_id"] == student_id)

    if not (is_passenger or is_host):
        raise HTTPException(status_code=403, detail="Unauthorized to cancel this booking.")

    if req["status"] in ["Cancelled", "Rejected"]:
        raise HTTPException(status_code=400, detail=f"Booking is already {req['status'].lower()}.")

    if req["status"] == "Accepted":
        cursor.execute(
            "DELETE FROM confirmed_bookings WHERE ride_id = ? AND passenger_id = ?",
            (req["ride_id"], req["passenger_id"])
        )
        cursor.execute(
            "UPDATE rides SET available_seat = available_seat + 1, status = 'Available' WHERE id = ?",
            (req["ride_id"],)
        )

    cursor.execute("UPDATE booking_requests SET status = 'Cancelled' WHERE id = ?", (request_id,))

    recipient_id = req["host_id"] if is_passenger else req["passenger_id"]
    canceler_role = "Passenger" if is_passenger else "Host"

    cursor.execute(
        """
        INSERT INTO notifications (student_id, title, message, is_read)
        VALUES (?, ?, ?, 0)
        """,
        (
            recipient_id,
            "Booking Cancelled",
            f"The {canceler_role} has cancelled the booking for ride from {req['from_place']} to {req['to_place']}."
        )
    )

    db.commit()
    return {"message": "Booking successfully cancelled."}