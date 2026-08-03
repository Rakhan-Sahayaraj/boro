from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from utils import verify_token

# tokenUrl should point to your login endpoint path
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_student(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = verify_token(token)

    if payload is None:
        raise credentials_exception

    # Optional check: Ensure the student_id or reg_no actually exists in the token payload
    if not payload.get("student_id") and not payload.get("id"):
        raise credentials_exception

    return payload