import sqlite3 from "sqlite3";

const db = new sqlite3.Database("ridelog.sqlite");

export const initDB = () => {
  db.serialize(() => {
    db.run('PRAGMA foreign_keys = ON');

    // 1. Users
    db.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

    // 2. Rides (OHNE seats_occupied)
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

    // 3. Ride Passengers
    db.run(`CREATE TABLE IF NOT EXISTS ride_passengers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ride_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT CHECK(status IN ('joined', 'cancelled')) DEFAULT 'joined',
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(ride_id) REFERENCES rides(id),
            FOREIGN KEY(user_id) REFERENCES users(id),
            UNIQUE(ride_id, user_id)
        )`);

        // 4. Groups
        db.run(`CREATE TABLE IF NOT EXISTS groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            code TEXT UNIQUE NOT NULL,
            owner_user_id INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(owner_user_id) REFERENCES users(id)
          )`);

        // 5. Group Members
        db.run(`CREATE TABLE IF NOT EXISTS group_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            role TEXT CHECK(role IN ('admin', 'member')) DEFAULT 'member',
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id),
            UNIQUE(group_id, user_id)
          )`);

    db.get("SELECT COUNT(*) as count FROM groups", (groupErr, groupRow: any) => {
      if (!groupErr && groupRow.count === 0) {
        const groupSql = `INSERT INTO groups (name, code, owner_user_id) VALUES (?, ?, ?)`;
        const groupMemberSql = `INSERT OR IGNORE INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)`;

        db.run(groupSql, ['Linz High School Carpool', 'LHS2024', 1], function (err) {
          if (err) return;
          const groupId1 = this.lastID;
          db.run(groupMemberSql, [groupId1, 1, 'admin']);
          db.run(groupMemberSql, [groupId1, 2, 'member']);
          db.run(groupMemberSql, [groupId1, 3, 'member']);
        });

        db.run(groupSql, ['Downtown Office Commuters', 'DOC456', 2], function (err) {
          if (err) return;
          const groupId2 = this.lastID;
          db.run(groupMemberSql, [groupId2, 2, 'admin']);
          db.run(groupMemberSql, [groupId2, 1, 'member']);
        });
      }
    });

        // 6. Seeding
    db.get("SELECT COUNT(*) as count FROM users", (err, row: any) => {
      if (!err && row.count === 0) {
        console.log("Starte sauberes Seeding ohne Redundanz...");

        const userSql = `INSERT INTO users (name, email) VALUES (?, ?)`;
        const ridesSql = `INSERT INTO rides (driver_user_id, start_name, end_name, depart_time, seats_total, distance_km, note, price_per_seat) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
        const passSql = `INSERT INTO ride_passengers (ride_id, user_id, status) VALUES (?, ?, 'joined')`;
          const groupSql = `INSERT INTO groups (name, code, owner_user_id) VALUES (?, ?, ?)`;
          const groupMemberSql = `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)`;

        db.run(userSql, ['Felix Wimplinger', 'felix@ridelog.com'], () => {
          db.run(userSql, ['Max Mustermann', 'max@ridelog.com'], () => {
            db.run(userSql, ['Simon Sebulba', 'sebulba@ridelog.com'], () => {
              db.run(userSql, ['Thorsten Legat', 'legat@ridelog.com'], () => {
                
                console.log("Users fertig. Seede Rides...");
                // Achtung: seats_occupied ist hier im SQL-String und in den Parametern gelöscht!
                db.run(ridesSql, [1, 'Linz Hbf', 'HTL Leonding', '2026-03-09 07:45:00', 4, 5.2, 'Eingang', 0.0]);
                db.run(ridesSql, [2, 'Wels West', 'Linz Zentrum', '2026-03-09 08:15:00', 3, 25.0, 'Voll!', 2.5]);
                db.run(ridesSql, [3, 'Traun', 'Haid Center', '2026-03-09 16:00:00', 2, 8.5, 'Parkplatz', null]);
                db.run(ridesSql, [1, 'Steyr', 'Linz', '2026-03-10 07:00:00', 4, 40.0, 'Wöchentlich', 4.0]);
                db.run(ridesSql, [4, 'Braunau', 'Salzburg', '2026-03-11 09:30:00', 5, 65.0, 'Dienst', null], () => {
                  
                  console.log("Rides fertig. Seede echte Passagiere...");
                  // Hier erzeugen wir jetzt die "belegten Plätze"
                  db.run(passSql, [1, 2]); // Max fährt bei Felix (Fahrt 1) mit -> seats_occupied wird 1
                  db.run(passSql, [2, 1]); // Felix fährt bei Max (Fahrt 2) mit
                  db.run(passSql, [2, 3]); // Simon fährt bei Max (Fahrt 2) mit
                  db.run(passSql, [2, 4]); // Thorsten fährt bei Max (Fahrt 2) mit -> seats_occupied wird 3 (Voll!)
                  db.run(passSql, [4, 1]); // Felix fährt bei Thorsten (Fahrt 4) mit

                  db.run(groupSql, ['Linz High School Carpool', 'LHS2024', 1], function () {
                    const groupId1 = this.lastID;
                    db.run(groupMemberSql, [groupId1, 1, 'admin']);
                    db.run(groupMemberSql, [groupId1, 2, 'member']);
                    db.run(groupMemberSql, [groupId1, 3, 'member']);

                    db.run(groupSql, ['Downtown Office Commuters', 'DOC456', 2], function () {
                      const groupId2 = this.lastID;
                      db.run(groupMemberSql, [groupId2, 2, 'admin']);
                      db.run(groupMemberSql, [groupId2, 1, 'member']);

                      console.log('Vollständiges Seeding beendet.');
                    });
                  });
                });
              });
            });
          });
        });
      }
    });
  });
};

export default db;