import os
import sqlite3
import pytest
from fastapi.testclient import TestClient

from main import app
from database import get_db

TEST_DB_FILE = "test_boro.db"

def get_test_db():
    conn = sqlite3.connect(TEST_DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

# Override FastAPI's database dependency
app.dependency_overrides[get_db] = get_test_db

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_test_database():
    """Initializes clean test tables before each test run and cleans up after."""
    with sqlite3.connect(TEST_DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute("PRAGMA foreign_keys = OFF;")
        cursor.execute("DROP TABLE IF EXISTS chat_messages;")
        cursor.execute("DROP TABLE IF EXISTS notifications;")
        cursor.execute("DROP TABLE IF EXISTS confirmed_bookings;")
        cursor.execute("DROP TABLE IF EXISTS booking_requests;")
        cursor.execute("DROP TABLE IF EXISTS rides;")
        cursor.execute("DROP TABLE IF EXISTS students;")
        
        # Schema definition
        cursor.execute("""
            CREATE TABLE students (
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
            );
        """)
        cursor.execute("""
            CREATE TABLE rides (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                host_id INTEGER NOT NULL,
                from_place TEXT NOT NULL,
                to_place TEXT NOT NULL,
                ride_date TEXT NOT NULL,
                ride_time TEXT NOT NULL,
                helmet INTEGER DEFAULT 0,
                available_seat INTEGER DEFAULT 1,
                status TEXT DEFAULT 'Available',
                message TEXT
            );
        """)
        cursor.execute("""
            CREATE TABLE booking_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ride_id INTEGER NOT NULL,
                passenger_id INTEGER NOT NULL,
                status TEXT DEFAULT 'Pending'
            );
        """)
        cursor.execute("""
            CREATE TABLE confirmed_bookings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ride_id INTEGER NOT NULL,
                host_id INTEGER NOT NULL,
                passenger_id INTEGER NOT NULL
            );
        """)
        cursor.execute("""
            CREATE TABLE notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                message TEXT NOT NULL,
                is_read INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        cursor.execute("""
            CREATE TABLE chat_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                booking_id INTEGER NOT NULL,
                sender_id INTEGER NOT NULL,
                message TEXT,
                proposed_price REAL,
                status TEXT DEFAULT 'pending',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
    
    yield
    
    # Teardown: Remove test DB file after tests finish
    if os.path.exists(TEST_DB_FILE):
        os.remove(TEST_DB_FILE)

HOST_STUDENT = {
    "name": "Alex Mercer",
    "reg_no": "REG2026001",
    "college": "Tech Institute",
    "phone": "9876543210",
    "password": "Password123",
    "has_bike": True,
    "bike_model": "Duke 390",
    "bike_number": "KA01AB1234"
}

PASSENGER_STUDENT = {
    "name": "Sarah Connor",
    "reg_no": "REG2026002",
    "college": "Tech Institute",
    "phone": "9876543211",
    "password": "Password123",
    "has_bike": False,
    "bike_model": None,
    "bike_number": None
}

def test_full_boro_workflow():
    print("\n--- 1. REGISTERING STUDENTS ---")
    res_host_reg = client.post("/auth/register", json=HOST_STUDENT)
    assert res_host_reg.status_code in [200, 201], f"Host Reg Failed: {res_host_reg.text}"

    res_pass_reg = client.post("/auth/register", json=PASSENGER_STUDENT)
    assert res_pass_reg.status_code in [200, 201], f"Passenger Reg Failed: {res_pass_reg.text}"
    print("✓ Students Registered Successfully")

    print("\n--- 2. LOGGING IN ---")
    res_host_login = client.post(
        "/auth/login",
        data={"username": HOST_STUDENT["reg_no"], "password": HOST_STUDENT["password"]}
    )
    assert res_host_login.status_code == 200, f"Host Login Failed: {res_host_login.text}"
    host_token = res_host_login.json()["access_token"]
    host_headers = {"Authorization": f"Bearer {host_token}"}

    res_pass_login = client.post(
        "/auth/login",
        data={"username": PASSENGER_STUDENT["reg_no"], "password": PASSENGER_STUDENT["password"]}
    )
    assert res_pass_login.status_code == 200, f"Passenger Login Failed: {res_pass_login.text}"
    passenger_token = res_pass_login.json()["access_token"]
    passenger_headers = {"Authorization": f"Bearer {passenger_token}"}
    print("✓ Both Students Authenticated Successfully")

    print("\n--- 3. POSTING & SEARCHING RIDES ---")
    ride_data = {
        "from_place": "Campus North Gate",
        "to_place": "Metro Station",
        "ride_date": "2026-08-01",
        "ride_time": "09:00 AM",
        "helmet": True,
        "available_seat": 1,
        "message": "Leaving from north gate"
    }
    res_post_ride = client.post("/ride/post", headers=host_headers, json=ride_data)
    assert res_post_ride.status_code in [200, 201], f"Ride Post Failed: {res_post_ride.text}"

    res_all_rides = client.get("/ride/all", headers=passenger_headers)
    assert res_all_rides.status_code == 200
    rides = res_all_rides.json()
    assert len(rides) > 0, "No rides returned in search"
    first_ride = rides[0]
    ride_id = first_ride.get("id") or first_ride.get("ride_id")
    print(f"✓ Ride Posted & Found (Ride ID: {ride_id})")

    print("\n--- 4. BOOKING REQUEST & ACCEPTANCE ---")
    res_req = client.post("/booking/request", headers=passenger_headers, json={"ride_id": ride_id})
    assert res_req.status_code in [200, 201], f"Booking Request Failed: {res_req.text}"

    res_incoming = client.get("/booking/ride-requests", headers=host_headers)
    assert res_incoming.status_code == 200
    incoming_requests = res_incoming.json()
    assert len(incoming_requests) > 0, "Host received no ride requests"
    first_req = incoming_requests[0]
    request_id = first_req.get("id") or first_req.get("request_id")

    res_accept = client.put(f"/booking/accept/{request_id}", headers=host_headers)
    assert res_accept.status_code == 200, f"Accept Request Failed: {res_accept.text}"
    print(f"✓ Ride Requested & Accepted (Request ID: {request_id})")