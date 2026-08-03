import sqlite3
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from database import get_db
from auth import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])

class ChatMessageSchema(BaseModel):
    booking_id: int
    message: Optional[str] = None
    proposed_price: Optional[float] = None

@router.post("/send")
def send_message(
    data: ChatMessageSchema,
    current_user: dict = Depends(get_current_user),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    sender_id = current_user["student_id"]

    cursor.execute(
        """
        INSERT INTO chat_messages (booking_id, sender_id, message, proposed_price, status, created_at)
        VALUES (?, ?, ?, ?, 'pending', datetime('now'))
        """,
        (data.booking_id, sender_id, data.message, data.proposed_price)
    )
    db.commit()
    return {"message": "Sent successfully"}

@router.get("/{booking_id}")
def get_chat(
    booking_id: int,
    current_user: dict = Depends(get_current_user),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    user_id = current_user["student_id"]

    cursor.execute(
        """
        SELECT id, booking_id, sender_id, message, proposed_price, status, created_at
        FROM chat_messages
        WHERE booking_id = ?
        ORDER BY id ASC
        """,
        (booking_id,)
    )
    rows = cursor.fetchall()

    messages = []
    for r in rows:
        messages.append({
            "id": r["id"],
            "booking_id": r["booking_id"],
            "sender_id": r["sender_id"],
            "message": r["message"],
            "proposed_price": r["proposed_price"],
            "status": r["status"],
            "is_me": (r["sender_id"] == user_id)
        })
    return messages