from fastapi import Header, HTTPException, status
from app.auth import extract_token_from_header, verify_token

async def get_current_user(authorization: str = Header(None)) -> dict:
    """
    Iron-clad retrieval of the current user from JWT token.
    Strictly raises 401 Unauthorized for any invalid token.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing"
        )
    
    token = extract_token_from_header(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format"
        )
    
    payload = verify_token(token)
    if not payload:
        # verify_token returns None on any jose.JWTError
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing user identity"
        )
    
    return {"user_id": user_id}
