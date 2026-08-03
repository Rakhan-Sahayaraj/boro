import sqlite3

DATABASE_NAME = "boro.db"

def get_db_connection():
    """Returns a new SQLite database connection with row access by column name."""
    connection = sqlite3.connect(DATABASE_NAME, check_same_thread=False)
    connection.row_factory = sqlite3.Row  # Allows accessing columns by name
    return connection

def get_db():
    """FastAPI Dependency for database access with auto-cleanup and rollback."""
    conn = get_db_connection()
    try:
        yield conn
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def init_db():
    """Creates database tables if they do not exist."""
    with get_db_connection() as connection:
        cursor = connection.cursor()

        # Enforce Foreign Key constraints in SQLite
        cursor.execute("PRAGMA foreign_keys = ON;")

        # 1. Students Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            reg_no TEXT UNIQUE NOT NULL,
            college TEXT NOT NULL,
            phone TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            has_bike INTEGER NOT NULL DEFAULT 0,
            bike_model TEXT,
            bike_number TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        # 2. Rides Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS rides (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            host_id INTEGER NOT NULL,
            from_place TEXT NOT NULL,
            to_place TEXT NOT NULL,
            ride_date TEXT NOT NULL,
            ride_time TEXT NOT NULL,
            available_seat INTEGER DEFAULT 1,
            helmet INTEGER DEFAULT 0,
            status TEXT DEFAULT 'Available',
            FOREIGN KEY(host_id) REFERENCES students(id) ON DELETE CASCADE
        )
        """)

        # 3. Booking Requests Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS booking_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ride_id INTEGER NOT NULL,
            passenger_id INTEGER NOT NULL,
            status TEXT DEFAULT 'Pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(ride_id) REFERENCES rides(id) ON DELETE CASCADE,
            FOREIGN KEY(passenger_id) REFERENCES students(id) ON DELETE CASCADE
        )
        """)

        # 4. Confirmed Bookings Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS confirmed_bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ride_id INTEGER NOT NULL,
            host_id INTEGER NOT NULL,
            passenger_id INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(ride_id) REFERENCES rides(id) ON DELETE CASCADE,
            FOREIGN KEY(host_id) REFERENCES students(id) ON DELETE CASCADE,
            FOREIGN KEY(passenger_id) REFERENCES students(id) ON DELETE CASCADE
        )
        """)

        # 5. Notifications Table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE
        )
        """)

        connection.commit()
    print("Database Ready!")

# Initialize tables on load
init_db()