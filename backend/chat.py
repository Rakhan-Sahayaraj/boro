import sqlite3
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from database import get_db
from dependencies import get_current_student

router = APIRouter(prefix="/chat", tags=["Chat"])


class ChatMessageSchema(BaseModel):
    booking_id: int
    message: Optional[str] = None
    proposed_price: Optional[float] = None


class ProposalResponseSchema(BaseModel):
    status: str  # 'accepted' or 'rejected'


# --- SEND TEXT MESSAGE ---
@router.post("/send")
def send_message(
    data: ChatMessageSchema,
    current_user: dict = Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    sender_id = current_user.get("id") or current_user.get("student_id")

    cursor.execute(
        """
        INSERT INTO chat_messages (booking_id, sender_id, message, proposed_price, status, created_at)
        VALUES (?, ?, ?, ?, 'pending', datetime('now'))
        """,
        (data.booking_id, sender_id, data.message, data.proposed_price)
    )
    db.commit()
    return {"message": "Sent successfully"}


# --- SEND PRICE PROPOSAL ---
@router.post("/propose-price")
def propose_price(
    data: ChatMessageSchema,
    current_user: dict = Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    sender_id = current_user.get("id") or current_user.get("student_id")

    if data.proposed_price is None or data.proposed_price <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A valid proposed_price is required."
        )

    cursor.execute(
        """
        INSERT INTO chat_messages (booking_id, sender_id, message, proposed_price, status, created_at)
        VALUES (?, ?, ?, ?, 'pending', datetime('now'))
        """,
        (data.booking_id, sender_id, data.message, data.proposed_price)
    )
    db.commit()
    return {"message": "Price proposal sent"}


# --- ACCEPT / REJECT PROPOSAL ---
@router.put("/proposal/{proposal_id}")
def respond_to_proposal(
    proposal_id: int,
    data: ProposalResponseSchema,
    current_user: dict = Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()

    if data.status not in ('accepted', 'rejected'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status must be 'accepted' or 'rejected'."
        )

    cursor.execute("SELECT * FROM chat_messages WHERE id = ?", (proposal_id,))
    proposal = cursor.fetchone()

    if not proposal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proposal not found."
        )

    if proposal["proposed_price"] is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This message is not a price proposal."
        )

    cursor.execute(
        "UPDATE chat_messages SET status = ? WHERE id = ?",
        (data.status, proposal_id)
    )
    db.commit()
    return {"message": f"Proposal {data.status}"}


# --- GET CHAT MESSAGES ---
@router.get("/{booking_id}")
def get_chat(
    booking_id: int,
    current_user: dict = Depends(get_current_student),
    db: sqlite3.Connection = Depends(get_db)
):
    db.row_factory = sqlite3.Row
    cursor = db.cursor()
    user_id = current_user.get("id") or current_user.get("student_id")

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