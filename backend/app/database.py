"""
MongoDB database connection and utilities.
Handles connection pooling and database access.
"""
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# MongoDB Client
mongodb_client: MongoClient = None
database = None


async def connect_to_mongo():
    """Connect to MongoDB and initialize the database."""
    global mongodb_client, database
    try:
        mongodb_client = MongoClient(settings.MONGODB_URL)
        # Test connection
        mongodb_client.admin.command('ping')
        database = mongodb_client[settings.DATABASE_NAME]
        database.users.create_index('email', unique=True)
        database.users.create_index('total_points')
        database.focus_sessions.create_index([('user_id', 1), ('created_at', -1)])
        database.block_events.create_index([('user_id', 1), ('created_at', -1)])
        logger.info("Connected to MongoDB successfully")
    except ConnectionFailure as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise


async def close_mongo_connection():
    """Close the MongoDB connection."""
    global mongodb_client
    if mongodb_client:
        mongodb_client.close()
        logger.info("Closed MongoDB connection")


def get_database():
    """Get the database instance."""
    return database
