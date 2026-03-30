from datetime import datetime, timezone
from bson.objectid import ObjectId
from fastapi import HTTPException, status

def to_object_id(user_id: str) -> ObjectId:
    try:
        return ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user id in token"
        ) from exc


def ensure_user_points_fields(db, user_object_id: ObjectId) -> dict:
    user_doc = db.users.find_one({"_id": user_object_id})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    set_defaults = {}
    for field in (
        "total_points",
        "lifetime_focus_minutes",
        "lifetime_focus_sessions",
        "lifetime_block_screens",
        "lifetime_points_lost",
    ):
        if field not in user_doc:
            set_defaults[field] = 0

    if set_defaults:
        set_defaults["updated_at"] = datetime.now(timezone.utc)
        db.users.update_one(
            {"_id": user_object_id},
            {"$set": set_defaults}
        )
        user_doc = db.users.find_one({"_id": user_object_id})

    return user_doc


def aggregate_day_stats(db, user_object_id: ObjectId, start_dt: datetime, end_dt: datetime) -> dict:
    focus_pipeline = [
        {
            "$match": {
                "user_id": user_object_id,
                "created_at": {"$gte": start_dt, "$lt": end_dt},
            }
        },
        {
            "$group": {
                "_id": None,
                "count": {"$sum": 1},
                "minutes": {"$sum": "$duration_minutes"},
                "points": {"$sum": "$points_delta"},
            }
        },
    ]

    block_pipeline = [
        {
            "$match": {
                "user_id": user_object_id,
                "created_at": {"$gte": start_dt, "$lt": end_dt},
            }
        },
        {
            "$group": {
                "_id": None,
                "count": {"$sum": 1},
                "points_lost": {"$sum": {"$multiply": ["$points_delta", -1]}},
            }
        },
    ]

    focus_summary = next(iter(db.focus_sessions.aggregate(focus_pipeline)), None)
    block_summary = next(iter(db.block_events.aggregate(block_pipeline)), None)

    focus_sessions_count = int((focus_summary or {}).get("count", 0))
    focus_minutes = int((focus_summary or {}).get("minutes", 0))
    focus_points_gained = int((focus_summary or {}).get("points", 0))
    block_screens_count = int((block_summary or {}).get("count", 0))
    points_lost = int((block_summary or {}).get("points_lost", 0))

    return {
        "focus_sessions_count": focus_sessions_count,
        "focus_minutes": focus_minutes,
        "focus_points_gained": focus_points_gained,
        "block_screens_count": block_screens_count,
        "points_lost": points_lost,
        "net_points": focus_points_gained - points_lost,
    }


def analytics_message(series: list[dict], trend: str) -> str:
    if not series:
        return "Start today. Even 10 focused minutes can change your week."

    last = series[-1]
    if last["focus_minutes"] >= 60 and last["block_screens_count"] == 0:
        return "Excellent discipline today. Keep this rhythm and your ranking will keep rising."

    if trend == "improving":
        return "Great progress. Your consistency is building real momentum."

    if trend == "declining":
        return "Progress dipped recently. Reset with one deep focus session now and bounce back."

    return "Stay steady. Small focused wins every day lead to major long-term growth."
