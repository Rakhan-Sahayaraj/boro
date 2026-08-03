import sqlite3
from fastapi import APIRouter, Depends, HTTPException, status
from dependencies import get_current_student
from database import get_db

router = APIRouter(
    prefix="/notification",
    tags=["Notification"]
)


# ==========================
# My Notifications
# ==========================

@router.get("/")
def get_notifications(
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        SELECT
            id,
            title,
            message,
            is_read,
            created_at
        FROM notifications
        WHERE student_id = ?
        ORDER BY created_at DESC
        """,
        (student_id,)
    )

    rows = cursor.fetchall()

    # Convert database rows to formatted JSON dictionaries
    notifications = [
        {
            "id": row["id"],
            "title": row["title"],
            "message": row["message"],
            "is_read": bool(row["is_read"]),
            "created_at": row["created_at"]
        }
        for row in rows
    ]

    return {"notifications": notifications}


# ==========================
# Mark Notification as Read
# ==========================

@router.put("/read/{notification_id}")
def mark_as_read(
    notification_id: int,
    current_student=Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    cursor = db.cursor()

    student_id = current_student.get("student_id") or current_student.get("id")

    cursor.execute(
        """
        UPDATE notifications
        SET is_read = 1
        WHERE id = ? AND student_id = ?
        """,
        (notification_id, student_id)
    )

    if cursor.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found or unauthorized."
        )

    db.commit()

    return {"message": "Notification marked as read."}