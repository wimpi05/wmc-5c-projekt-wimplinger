import sqlite3 from 'sqlite3';

const db = new sqlite3.Database('ridelog.sqlite');

export const initDB = () => {
    db.serialize(() => { 
        // Users
        db.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

        // Rides
        db.run(`CREATE TABLE IF NOT EXISTS rides (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            driver_user_id INTEGER,
            start_name TEXT,
            end_name TEXT,
            depart_time DATETIME,
            seats_total INTEGER,
            price_per_seat REAL,
            distance_km REAL,
            note TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(driver_user_id) REFERENCES users(id)
        )`);

        // Ride Passengers
        db.run(`CREATE TABLE IF NOT EXISTS ride_passengers (
            ride_id INTEGER,
            user_id INTEGER,
            status TEXT CHECK(status IN ('joined', 'cancelled')), [cite: 309]
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (ride_id, user_id),
            FOREIGN KEY(ride_id) REFERENCES rides(id),
            FOREIGN KEY(user_id) REFERENCES users(id)
        )`);
    });
};

export default db;