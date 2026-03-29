from datetime import datetime, timedelta, time
from fastapi import APIRouter, Depends, status
from app.database import get_database
from app.schemas import (
    FocusSessionEventRequest, BlockScreenEventRequest, PointEventResponse,
    TodayStatsResponse, AnalyticsDay, AnalyticsResponse
)
from app.dependencies import get_current_user
from app.utils.stats_utils import (
    to_object_id, ensure_user_points_fields, aggregate_day_stats, analytics_message
)
import logging

logger = logging.getLogger(__name__)

# Enforce authentication for ALL stats endpoints
router = APIRouter(
    prefix="/stats",
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)

@router.post("/events/focus-session", response_model=PointEventResponse)
async def log_focus_session_event(
    request: FocusSessionEventRequest,
    current_user: dict = Depends(get_current_user)
):
    """Log a focus session and award points."""
    db = get_database()
    user_object_id = to_object_id(current_user["user_id"])
    ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    start_at = request.started_at or now
    end_at = start_at + timedelta(minutes=request.duration_minutes)
    points_delta = request.duration_minutes

    db.focus_sessions.insert_one({
        "user_id": user_object_id,
        "duration_minutes": request.duration_minutes,
        "points_delta": points_delta,
        "started_at": start_at,
        "ended_at": end_at,
        "created_at": now,
    })

    db.users.update_one(
        {"_id": user_object_id},
        {
            "$inc": {
                "total_points": points_delta,
                "lifetime_focus_minutes": request.duration_minutes,
                "lifetime_focus_sessions": 1,
            },
            "$set": {"updated_at": now},
        }
    )

    user_doc = db.users.find_one({"_id": user_object_id})
    return PointEventResponse(
        message="Focus session points added",
        points_delta=points_delta,
        total_points=int(user_doc.get("total_points", 0)),
    )


@router.post("/events/block-screen", response_model=PointEventResponse)
async def log_block_screen_event(
    request: BlockScreenEventRequest,
    current_user: dict = Depends(get_current_user)
):
    """Log a distracting app block event and deduct points."""
    db = get_database()
    user_object_id = to_object_id(current_user["user_id"])
    ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    points_delta = -request.points_penalty

    db.block_events.insert_one({
        "user_id": user_object_id,
        "reason": request.reason,
        "package_name": request.package_name,
        "points_delta": points_delta,
        "created_at": now,
    })

    db.users.update_one(
        {"_id": user_object_id},
        {
            "$inc": {
                "total_points": points_delta,
                "lifetime_block_screens": 1,
                "lifetime_points_lost": request.points_penalty,
            },
            "$set": {"updated_at": now},
        }
    )

    user_doc = db.users.find_one({"_id": user_object_id})
    return PointEventResponse(
        message="Block screen penalty applied",
        points_delta=points_delta,
        total_points=int(user_doc.get("total_points", 0)),
    )


@router.get("/me/today", response_model=TodayStatsResponse)
async def get_today_stats(current_user: dict = Depends(get_current_user)):
    """Get current user's productivity summary for today."""
    db = get_database()
    user_object_id = to_object_id(current_user["user_id"])
    user_doc = ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    today_start = datetime.combine(now.date(), time.min)
    tomorrow_start = today_start + timedelta(days=1)
    stats = aggregate_day_stats(db, user_object_id, today_start, tomorrow_start)

    return TodayStatsResponse(
        date=now.date(),
        total_points=int(user_doc.get("total_points", 0)),
        focus_sessions_count=stats["focus_sessions_count"],
        focus_minutes=stats["focus_minutes"],
        focus_points_gained=stats["focus_points_gained"],
        block_screens_count=stats["block_screens_count"],
        points_lost=stats["points_lost"],
        net_points_today=stats["net_points"],
    )


@router.get("/me/analytics", response_model=AnalyticsResponse)
async def get_analytics(
    days: int = 7,
    current_user: dict = Depends(get_current_user)
):
    """Get historical productivity analytics."""
    from fastapi import HTTPException
    if days < 3 or days > 30:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="days must be between 3 and 30"
        )

    db = get_database()
    user_object_id = to_object_id(current_user["user_id"])
    ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow().date()
    start_day = now - timedelta(days=days - 1)
    series_raw = []

    for day_offset in range(days):
        target_day = start_day + timedelta(days=day_offset)
        day_start = datetime.combine(target_day, time.min)
        day_end = day_start + timedelta(days=1)
        day_stats = aggregate_day_stats(db, user_object_id, day_start, day_end)
        series_raw.append({"date": target_day, **day_stats})

    # Simple trend calculation logic
    first_half = series_raw[: max(1, days // 2)]
    second_half = series_raw[max(1, days // 2):]

    first_avg = sum(item["net_points"] for item in first_half) / len(first_half)
    second_avg = sum(item["net_points"] for item in second_half) / len(second_half)

    if second_avg > first_avg + 1:
        trend = "improving"
    elif second_avg < first_avg - 1:
        trend = "declining"
    else:
        trend = "stable"

    return AnalyticsResponse(
        days=days,
        series=[
            AnalyticsDay(
                date=item["date"],
                focus_sessions_count=item["focus_sessions_count"],
                focus_minutes=item["focus_minutes"],
                focus_points_gained=item["focus_points_gained"],
                block_screens_count=item["block_screens_count"],
                points_lost=item["points_lost"],
                net_points=item["net_points"],
            )
            for item in series_raw
        ],
        trend=trend,
        message=analytics_message(series_raw, trend),
    )
