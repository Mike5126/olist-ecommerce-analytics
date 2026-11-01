from database import get_engine
from sqlalchemy import text

engine = get_engine()

try:
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT current_database();")
        )

        print("Connection successful!")
        print("Database:", result.scalar()) # Take the first cell

except Exception as e:
    print("Connection failed:", e) 