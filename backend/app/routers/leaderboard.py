from fastapi import APIRouter, Depends, HTTPException, status
from app.database import get_database
from app.schemas import LeaderboardEntry, LeaderboardResponse
from app.dependencies import get_current_user
from app.utils.stats_utils import to_object_id, ensure_user_points_fields
import logging

logger = logging.getLogger(__name__)

# Enforce authentication for ALL leaderboard endpoints
router = APIRouter(
    prefix="/leaderboard",
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)

@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    limit: int = 20,
    current_user: dict = Depends(get_current_user)
):
    """
    Get global leaderboard.
    Standardized limit is 1-100.
    """
    if limit < 1 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="limit must be between 1 and 100"
        )

    db = get_database()
    current_user_object_id = to_object_id(current_user["user_id"])
    current_user_doc = ensure_user_points_fields(db, current_user_object_id)
    current_points = int(current_user_doc.get("total_points", 0))

    leaderboard_cursor = db.users.find(
        {},
        {"name": 1, "email": 1, "total_points": 1, "created_at": 1}
    ).sort([("total_points", -1), ("created_at", 1)]).limit(limit)

    leaderboard = []
    rank = 1
    for user_doc in leaderboard_cursor:
        leaderboard.append(
            LeaderboardEntry(
                rank=rank,
                user_id=str(user_doc["_id"]),
                name=user_doc.get("name", "Unknown"),
                email=user_doc.get("email", ""),
                total_points=int(user_doc.get("total_points", 0)),
            )
        )
        rank += 1

    better_count = db.users.count_documents({"total_points": {"$gt": current_points}})
    current_user_rank = better_count + 1

    return LeaderboardResponse(
        leaderboard=leaderboard,
        current_user_rank=current_user_rank,
        current_user_points=current_points,
    )
