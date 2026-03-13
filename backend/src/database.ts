import sqlite3 from 'sqlite3';
import bcrypt from 'bcryptjs';

const db = new sqlite3.Database('ridelog.sqlite');
const seededPasswordHash = bcrypt.hashSync('Passwort123!', 10);

const seedDefaultGroups = () => {
  const groupSql = `INSERT INTO groups (name, code, owner_user_id) VALUES (?, ?, ?)`;
  const groupMemberSql = `INSERT OR IGNORE INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)`;

  db.run(groupSql, ['Linz High School Carpool', 'LHS2024', 1], function () {
    const groupId1 = this.lastID;
    db.run(groupMemberSql, [groupId1, 1, 'admin']);
    db.run(groupMemberSql, [groupId1, 2, 'member']);
    db.run(groupMemberSql, [groupId1, 3, 'member']);

    db.run(groupSql, ['Downtown Office Commuters', 'DOC456', 2], function () {
      const groupId2 = this.lastID;
      db.run(groupMemberSql, [groupId2, 2, 'admin']);
      db.run(groupMemberSql, [groupId2, 1, 'member']);
    });
  });
};

const seedDefaultRides = () => {
  const ridesSql = `INSERT INTO rides (driver_user_id, group_id, start_name, end_name, depart_time, seats_total, distance_km, note, price_per_seat) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`;
  const passSql = `INSERT OR IGNORE INTO ride_passengers (ride_id, user_id, status) VALUES (?, ?, 'joined')`;

  db.run(ridesSql, [1, 1, 'Linz Hbf', 'HTL Leonding', '2026-03-09 07:45:00', 4, 5.2, 'Eingang', 0.0]);
  db.run(ridesSql, [2, 2, 'Wels West', 'Linz Zentrum', '2026-03-09 08:15:00', 3, 25.0, 'Voll!', 2.5]);
  db.run(ridesSql, [3, 1, 'Traun', 'Haid Center', '2026-03-09 16:00:00', 2, 8.5, 'Parkplatz', null]);
  db.run(ridesSql, [1, 1, 'Steyr', 'Linz', '2026-03-10 07:00:00', 4, 40.0, 'Wöchentlich', 4.0]);
  db.run(ridesSql, [4, 2, 'Braunau', 'Salzburg', '2026-03-11 09:30:00', 5, 65.0, 'Dienst', null], () => {
    db.run(passSql, [1, 2]);
    db.run(passSql, [2, 1]);
    db.run(passSql, [2, 3]);
    db.run(passSql, [2, 4]);
    db.run(passSql, [4, 1]);
  });
};

export const initDB = () => {
  db.serialize(() => {
    db.run('PRAGMA foreign_keys = ON');

    db.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            password_hash TEXT,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

    db.run(`CREATE TABLE IF NOT EXISTS rides (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            driver_user_id INTEGER,
            group_id INTEGER,
            start_name TEXT,
            end_name TEXT,
            depart_time DATETIME,
            seats_total INTEGER,
            price_per_seat REAL,
            distance_km REAL,
            note TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(driver_user_id) REFERENCES users(id),
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE SET NULL
        )`);

    db.run(`CREATE TABLE IF NOT EXISTS ride_passengers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ride_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT CHECK(status IN ('joined', 'cancelled')) DEFAULT 'joined',
            joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(ride_id) REFERENCES rides(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id),
            UNIQUE(ride_id, user_id)
        )`);

    db.run(`CREATE TABLE IF NOT EXISTS groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            code TEXT UNIQUE NOT NULL,
            owner_user_id INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(owner_user_id) REFERENCES users(id)
          )`);

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

    db.run(`CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token_hash TEXT NOT NULL UNIQUE,
            expires_at DATETIME NOT NULL,
            revoked_at DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )`);

    db.run(
      `UPDATE users SET password_hash = ? WHERE password_hash IS NULL OR password_hash = ''`,
      [seededPasswordHash],
    );

    const ensureGroupsAndRides = () => {
      db.get(`SELECT COUNT(*) as count FROM groups`, (groupErr, groupRow: any) => {
        if (!groupErr && groupRow.count === 0) {
          seedDefaultGroups();
        }

        db.get(`SELECT COUNT(*) as count FROM rides`, (rideErr, rideRow: any) => {
          if (!rideErr && rideRow.count === 0) {
            setTimeout(() => {
              seedDefaultRides();
            }, 150);
          }
        });
      });
    };

    db.get(`SELECT COUNT(*) as count FROM users`, (err, row: any) => {
      if (err) return;

      if (row.count === 0) {
        console.log('Starte sauberes Seeding ohne Redundanz...');

        const userSql = `INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)`;
        db.run(userSql, ['Felix Wimplinger', 'felix@ridelog.com', seededPasswordHash], () => {
          db.run(userSql, ['Max Mustermann', 'max@ridelog.com', seededPasswordHash], () => {
            db.run(userSql, ['Simon Sebulba', 'sebulba@ridelog.com', seededPasswordHash], () => {
              db.run(userSql, ['Thorsten Legat', 'legat@ridelog.com', seededPasswordHash], () => {
                ensureGroupsAndRides();
                setTimeout(() => {
                  console.log('Vollständiges Seeding beendet.');
                }, 250);
              });
            });
          });
        });
        return;
      }

      ensureGroupsAndRides();
    });
  });
};

export default db;
