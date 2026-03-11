import express, { Request, Response, NextFunction } from 'express';
import bodyParser from 'body-parser';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import sqlite3 from 'sqlite3';
import db, { initDB } from './database';

dotenv.config();

const app = express();
const port = 3000;

const jwtSecret = process.env.JWT_SECRET ?? 'dev-jwt-secret-change-me';
const accessTokenExpiresIn = '15m';
const refreshTokenTtlMs = 1000 * 60 * 60 * 24 * 14; // 14 days

app.use(express.json());
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

initDB();

type JwtPayload = {
  sub: string;
  type: 'access';
};

type AuthRequest = Request & {
  userId?: number;
};

type DbError = Error | null;
type DbRow = Record<string, unknown> | undefined;
type DbRows = Record<string, unknown>[];

const randomGroupCode = (): string => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i += 1) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
};

const selectGroupForUserSql = `
  SELECT
      g.id,
      g.name,
      g.code,
      g.owner_user_id,
      (SELECT COUNT(*) FROM group_members gm2 WHERE gm2.group_id = g.id) AS members_count,
      CASE WHEN g.owner_user_id = ? THEN 1 ELSE 0 END AS is_owner,
      gm.role as current_user_role
  FROM groups g
  INNER JOIN group_members gm ON gm.group_id = g.id AND gm.user_id = ?
  WHERE g.id = ?
`;

const userSelectFields = `id, name, email, created_at, is_active`;

const issueAccessToken = (userId: number): string => {
  return jwt.sign({ sub: String(userId), type: 'access' }, jwtSecret, {
    expiresIn: accessTokenExpiresIn,
  });
};

const tokenHash = (token: string): string => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

const issueRefreshToken = (userId: number, cb: (err: Error | null, token?: string) => void): void => {
  const token = crypto.randomBytes(48).toString('hex');
  const hash = tokenHash(token);
  const expiresAtIso = new Date(Date.now() + refreshTokenTtlMs).toISOString();

  db.run(
    `INSERT INTO auth_refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)` ,
    [userId, hash, expiresAtIso],
    (err: DbError) => {
      if (err) {
        cb(err as Error);
        return;
      }
      cb(null, token);
    },
  );
};

const attachOptionalUser = (req: AuthRequest, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    next();
    return;
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, jwtSecret) as JwtPayload;
    const parsed = Number(payload.sub);
    if (payload.type === 'access' && Number.isFinite(parsed)) {
      req.userId = parsed;
    }
  } catch {
    // optional auth: ignore invalid tokens here
  }

  next();
};

const requireAuth = (req: AuthRequest, res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Nicht autorisiert.' });
    return;
  }

  const token = header.slice('Bearer '.length);
  try {
    const payload = jwt.verify(token, jwtSecret) as JwtPayload;
    const parsed = Number(payload.sub);
    if (payload.type !== 'access' || !Number.isFinite(parsed)) {
      res.status(401).json({ error: 'Ungültiger Token.' });
      return;
    }
    req.userId = parsed;
    next();
  } catch {
    res.status(401).json({ error: 'Token abgelaufen oder ungültig.' });
  }
};

const resolveUserId = (req: AuthRequest): number | null => {
  if (req.userId != null) return req.userId;

  const bodyUser = Number((req.body as { user_id?: number }).user_id);
  if (Number.isFinite(bodyUser) && bodyUser > 0) return bodyUser;

  const queryUser = Number((req.query as { user_id?: string }).user_id);
  if (Number.isFinite(queryUser) && queryUser > 0) return queryUser;

  return null;
};

app.use(attachOptionalUser);

// --- AUTH ENDPOINTS ---
app.post('/auth/register', async (req: Request, res: Response): Promise<void> => {
  const { email, password, name } = req.body as { email?: string; password?: string; name?: string };
  const safeEmail = (email ?? '').trim().toLowerCase();
  const safeName = (name ?? '').trim() || 'Neuer Benutzer';

  if (!safeEmail || !password || password.length < 8) {
    res.status(400).json({ error: 'Email und Passwort (mind. 8 Zeichen) sind erforderlich.' });
    return;
  }

  try {
    const hash = await bcrypt.hash(password, 10);
    db.run(
      `INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)` ,
      [safeName, safeEmail, hash],
      function (this: sqlite3.RunResult, err: DbError) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            res.status(400).json({ error: 'Email existiert bereits.' });
            return;
          }
          res.status(500).json({ error: err.message });
          return;
        }

        const userId = this.lastID;
        const accessToken = issueAccessToken(userId);

        issueRefreshToken(userId, (refreshErr, refreshToken) => {
          if (refreshErr || !refreshToken) {
            res.status(500).json({ error: 'Session konnte nicht erstellt werden.' });
            return;
          }

          db.get(`SELECT ${userSelectFields} FROM users WHERE id = ?`, [userId], (userErr: DbError, userRow: DbRow) => {
            if (userErr) {
              res.status(500).json({ error: userErr.message });
              return;
            }

            res.status(201).json({
              access_token: accessToken,
              refresh_token: refreshToken,
              user: userRow,
            });
          });
        });
      },
    );
  } catch {
    res.status(500).json({ error: 'Registrierung fehlgeschlagen.' });
  }
});

app.post('/auth/login', async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body as { email?: string; password?: string };
  const safeEmail = (email ?? '').trim().toLowerCase();

  if (!safeEmail || !password) {
    res.status(400).json({ error: 'Email und Passwort sind erforderlich.' });
    return;
  }

  db.get(`SELECT id, password_hash, is_active FROM users WHERE email = ?`, [safeEmail], async (err: DbError, row: any) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (!row || !row.password_hash) {
      res.status(401).json({ error: 'Login fehlgeschlagen.' });
      return;
    }
    if (row.is_active === 0) {
      res.status(403).json({ error: 'Account ist deaktiviert.' });
      return;
    }

    const ok = await bcrypt.compare(password, row.password_hash);
    if (!ok) {
      res.status(401).json({ error: 'Login fehlgeschlagen.' });
      return;
    }

    const userId = Number(row.id);
    const accessToken = issueAccessToken(userId);

    issueRefreshToken(userId, (refreshErr, refreshToken) => {
      if (refreshErr || !refreshToken) {
        res.status(500).json({ error: 'Session konnte nicht erstellt werden.' });
        return;
      }

      db.get(`SELECT ${userSelectFields} FROM users WHERE id = ?`, [userId], (userErr: DbError, userRow: DbRow) => {
        if (userErr) {
          res.status(500).json({ error: userErr.message });
          return;
        }

        res.json({
          access_token: accessToken,
          refresh_token: refreshToken,
          user: userRow,
        });
      });
    });
  });
});

app.post('/auth/refresh', (req: Request, res: Response): void => {
  const { refresh_token } = req.body as { refresh_token?: string };
  if (!refresh_token) {
    res.status(400).json({ error: 'refresh_token fehlt.' });
    return;
  }

  const hash = tokenHash(refresh_token);
  db.get(
    `SELECT user_id, expires_at, revoked_at FROM auth_refresh_tokens WHERE token_hash = ?`,
    [hash],
    (err: DbError, row: any) => {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (!row || row.revoked_at) {
        res.status(401).json({ error: 'Ungültiger Refresh-Token.' });
        return;
      }

      const isExpired = new Date(row.expires_at).getTime() <= Date.now();
      if (isExpired) {
        res.status(401).json({ error: 'Refresh-Token abgelaufen.' });
        return;
      }

      const userId = Number(row.user_id);
      const newAccessToken = issueAccessToken(userId);

      res.json({ access_token: newAccessToken });
    },
  );
});

app.post('/auth/logout', (req: Request, res: Response): void => {
  const { refresh_token } = req.body as { refresh_token?: string };
  if (!refresh_token) {
    res.status(400).json({ error: 'refresh_token fehlt.' });
    return;
  }

  db.run(
    `UPDATE auth_refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?`,
    [tokenHash(refresh_token)],
    (err: DbError) => {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      res.json({ ok: true });
    },
  );
});

app.get('/auth/me', requireAuth, (req: AuthRequest, res: Response): void => {
  db.get(`SELECT ${userSelectFields} FROM users WHERE id = ?`, [req.userId], (err: DbError, row: DbRow) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (!row) {
      res.status(404).json({ error: 'Benutzer nicht gefunden.' });
      return;
    }
    res.json(row);
  });
});

// --- RIDE ENDPOINTS ---
app.get('/rides', (req: AuthRequest, res: Response) => {
  const sql = `
    SELECT DISTINCT
      r.*,
      g.name as group_name,
      u.name as driver_username,
      (SELECT COUNT(*) FROM ride_passengers rp WHERE rp.ride_id = r.id AND rp.status = 'joined') as seats_occupied,
      CASE
        WHEN ? IS NOT NULL AND EXISTS (
          SELECT 1
          FROM ride_passengers me
          WHERE me.ride_id = r.id AND me.user_id = ? AND me.status = 'joined'
        ) THEN 1
        ELSE 0
      END AS current_user_joined
    FROM rides r
    LEFT JOIN users u ON r.driver_user_id = u.id
    LEFT JOIN groups g ON g.id = r.group_id
    LEFT JOIN group_members gm ON gm.group_id = r.group_id
    WHERE (? IS NULL OR gm.user_id = ?)
    ORDER BY r.depart_time ASC
  `;

  db.all(sql, [req.userId ?? null, req.userId ?? null, req.userId ?? null, req.userId ?? null], (err: DbError, rows: DbRows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.get('/rides/:id', (req: AuthRequest, res: Response) => {
  const rideId = Number(req.params.id);
  if (!rideId) {
    res.status(400).json({ error: 'Ungültige Ride-ID.' });
    return;
  }

  const sql = `
    SELECT
      r.*,
      g.name as group_name,
      u.name as driver_username,
      (SELECT COUNT(*) FROM ride_passengers rp WHERE rp.ride_id = r.id AND rp.status = 'joined') as seats_occupied,
      CASE
        WHEN ? IS NOT NULL AND EXISTS (
          SELECT 1
          FROM ride_passengers me
          WHERE me.ride_id = r.id AND me.user_id = ? AND me.status = 'joined'
        ) THEN 1
        ELSE 0
      END AS current_user_joined
    FROM rides r
    LEFT JOIN users u ON r.driver_user_id = u.id
    LEFT JOIN groups g ON g.id = r.group_id
    WHERE r.id = ?
  `;

  db.get(sql, [req.userId ?? null, req.userId ?? null, rideId], (err: DbError, row: DbRow) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: 'Fahrt nicht gefunden.' });
    res.json(row);
  });
});

app.post('/rides', (req: AuthRequest, res: Response) => {
  const { driver_user_id, group_id, start_name, end_name, depart_time, seats_total, price_per_seat, distance_km, note } = req.body;

  const driverUserId = req.userId ?? Number(driver_user_id);
  const groupId = Number(group_id);
  const distanceKm = Number(distance_km);
  if (!driverUserId || !groupId || !start_name || !end_name || !depart_time || !seats_total) {
    res.status(400).json({ error: 'Pflichtfelder fehlen.' });
    return;
  }
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) {
    res.status(400).json({ error: 'distance_km muss größer als 0 sein.' });
    return;
  }

  db.get(
    `SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?`,
    [groupId, driverUserId],
    (membershipErr: DbError, membershipRow: DbRow) => {
      if (membershipErr) {
        res.status(500).json({ error: membershipErr.message });
        return;
      }
      if (!membershipRow) {
        res.status(403).json({ error: 'Du kannst nur Fahrten für eigene Gruppen erstellen.' });
        return;
      }

      const sql = `INSERT INTO rides (driver_user_id, group_id, start_name, end_name, depart_time, seats_total, price_per_seat, distance_km, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`;
      db.run(sql, [driverUserId, groupId, start_name, end_name, depart_time, seats_total, price_per_seat, distanceKm, note], function (this: sqlite3.RunResult, err: DbError) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID });
      });
    },
  );
});

app.post('/rides/:id/join', (req: AuthRequest, res: Response) => {
  const rideId = Number(req.params.id);
  const userId = resolveUserId(req);

  if (!rideId || !userId) {
    res.status(400).json({ error: 'ride_id und user_id sind erforderlich.' });
    return;
  }

  db.get(
    `
      SELECT
        r.id,
        r.driver_user_id,
        r.seats_total,
        (SELECT COUNT(*) FROM ride_passengers rp WHERE rp.ride_id = r.id AND rp.status = 'joined') AS seats_occupied
      FROM rides r
      WHERE r.id = ?
    `,
    [rideId],
    (rideErr: DbError, rideRow: any) => {
      if (rideErr) {
        res.status(500).json({ error: rideErr.message });
        return;
      }
      if (!rideRow) {
        res.status(404).json({ error: 'Fahrt nicht gefunden.' });
        return;
      }
      if (Number(rideRow.driver_user_id) === userId) {
        res.status(400).json({ error: 'Als Fahrer kannst du deiner eigenen Fahrt nicht beitreten.' });
        return;
      }
      if (Number(rideRow.seats_occupied) >= Number(rideRow.seats_total)) {
        res.status(409).json({ error: 'Fahrt ist bereits voll.' });
        return;
      }

      db.get(
        `SELECT id, status FROM ride_passengers WHERE ride_id = ? AND user_id = ?`,
        [rideId, userId],
        (passengerErr: DbError, passengerRow: any) => {
          if (passengerErr) {
            res.status(500).json({ error: passengerErr.message });
            return;
          }

          if (!passengerRow) {
            const insertSql = `INSERT INTO ride_passengers (ride_id, user_id, status) VALUES (?, ?, 'joined')`;
            db.run(insertSql, [rideId, userId], function (this: sqlite3.RunResult, insertErr: DbError) {
              if (insertErr) {
                res.status(500).json({ error: 'Beitritt fehlgeschlagen.' });
                return;
              }
              res.status(201).json({
                passenger_id: this.lastID,
                ride_id: rideId,
                user_id: userId,
                status: 'joined',
              });
            });
            return;
          }

          if (passengerRow.status === 'joined') {
            res.status(200).json({
              passenger_id: passengerRow.id,
              ride_id: rideId,
              user_id: userId,
              status: 'joined',
            });
            return;
          }

          db.run(
            `UPDATE ride_passengers SET status = 'joined' WHERE id = ?`,
            [passengerRow.id],
            (updateErr: DbError) => {
              if (updateErr) {
                res.status(500).json({ error: updateErr.message });
                return;
              }

              res.status(200).json({
                passenger_id: passengerRow.id,
                ride_id: rideId,
                user_id: userId,
                status: 'joined',
              });
            },
          );
        },
      );
    },
  );
});

app.post('/rides/:id/cancel', (req: AuthRequest, res: Response) => {
  const rideId = Number(req.params.id);
  const userId = resolveUserId(req);

  if (!rideId || !userId) {
    res.status(400).json({ error: 'ride_id und user_id sind erforderlich.' });
    return;
  }

  const sql = `UPDATE ride_passengers SET status = 'cancelled' WHERE ride_id = ? AND user_id = ? AND status = 'joined'`;
  db.run(sql, [rideId, userId], function (this: sqlite3.RunResult, err: DbError) {
    if (err) return res.status(500).json({ error: err.message });
    if (this.changes === 0) {
      return res.status(200).json({ message: 'Bereits verlassen.', status: 'cancelled' });
    }
    res.json({ message: 'Cancelled successfully', status: 'cancelled' });
  });
});

app.patch('/rides/:id', requireAuth, (req: AuthRequest, res: Response) => {
  const rideId = Number(req.params.id);
  const userId = req.userId as number;

  if (!rideId) {
    res.status(400).json({ error: 'Ungültige Ride-ID.' });
    return;
  }

  type UpdateRideBody = {
    group_id?: number;
    start_name?: string;
    end_name?: string;
    depart_time?: string;
    seats_total?: number;
    price_per_seat?: number | null;
    distance_km?: number | null;
    note?: string | null;
  };

  const body = req.body as UpdateRideBody;
  const groupId = Number(body.group_id);
  const startName = (body.start_name ?? '').trim();
  const endName = (body.end_name ?? '').trim();
  const departTime = (body.depart_time ?? '').trim();
  const seatsTotal = Number(body.seats_total);
  const distanceKm = Number(body.distance_km);

  if (!groupId || !startName || !endName || !departTime || !seatsTotal || seatsTotal <= 0) {
    res.status(400).json({ error: 'Pflichtfelder fehlen oder sind ungültig.' });
    return;
  }
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) {
    res.status(400).json({ error: 'distance_km muss größer als 0 sein.' });
    return;
  }

  db.get(`SELECT id, driver_user_id FROM rides WHERE id = ?`, [rideId], (rideErr: DbError, rideRow: any) => {
    if (rideErr) {
      res.status(500).json({ error: rideErr.message });
      return;
    }
    if (!rideRow) {
      res.status(404).json({ error: 'Fahrt nicht gefunden.' });
      return;
    }
    if (Number(rideRow.driver_user_id) !== userId) {
      res.status(403).json({ error: 'Nur der Fahrer darf diese Fahrt bearbeiten.' });
      return;
    }

    db.get(
      `SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?`,
      [groupId, userId],
      (membershipErr: DbError, membershipRow: DbRow) => {
        if (membershipErr) {
          res.status(500).json({ error: membershipErr.message });
          return;
        }
        if (!membershipRow) {
          res.status(403).json({ error: 'Du kannst nur Fahrten in deinen Gruppen bearbeiten.' });
          return;
        }

        const sql = `
          UPDATE rides
          SET group_id = ?,
              start_name = ?,
              end_name = ?,
              depart_time = ?,
              seats_total = ?,
              price_per_seat = ?,
              distance_km = ?,
              note = ?
          WHERE id = ?
        `;

        db.run(
          sql,
          [
            groupId,
            startName,
            endName,
            departTime,
            seatsTotal,
            body.price_per_seat ?? null,
            distanceKm,
            body.note ?? null,
            rideId,
          ],
          function (this: sqlite3.RunResult, updateErr: DbError) {
            if (updateErr) {
              res.status(500).json({ error: updateErr.message });
              return;
            }
            if (this.changes === 0) {
              res.status(404).json({ error: 'Fahrt nicht gefunden.' });
              return;
            }

            res.json({ updated: true, ride_id: rideId });
          },
        );
      },
    );
  });
});

app.delete('/rides/:id', requireAuth, (req: AuthRequest, res: Response) => {
  const rideId = Number(req.params.id);
  const userId = req.userId as number;

  if (!rideId) {
    res.status(400).json({ error: 'Ungültige Ride-ID.' });
    return;
  }

  db.get(`SELECT id, driver_user_id FROM rides WHERE id = ?`, [rideId], (rideErr: DbError, rideRow: any) => {
    if (rideErr) {
      res.status(500).json({ error: rideErr.message });
      return;
    }
    if (!rideRow) {
      res.status(404).json({ error: 'Fahrt nicht gefunden.' });
      return;
    }
    if (Number(rideRow.driver_user_id) !== userId) {
      res.status(403).json({ error: 'Nur der Fahrer darf diese Fahrt löschen.' });
      return;
    }

    db.run(`DELETE FROM rides WHERE id = ?`, [rideId], function (this: sqlite3.RunResult, deleteErr: DbError) {
      if (deleteErr) {
        res.status(500).json({ error: deleteErr.message });
        return;
      }
      if (this.changes === 0) {
        res.status(404).json({ error: 'Fahrt nicht gefunden.' });
        return;
      }

      res.json({ deleted: true, ride_id: rideId });
    });
  });
});

// --- STATS ENDPOINTS ---
app.get('/stats/rides', (_req: Request, res: Response) => {
  const sql = `
    SELECT
      COUNT(*) as totalRides,
      COALESCE(SUM(distance_km), 0) as totalKm,
      (COALESCE(SUM(distance_km), 0) * 0.2) as co2Saved
    FROM rides
  `;
  db.get(sql, [], (err: DbError, row: DbRow) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(row);
  });
});

app.get('/stats/me', requireAuth, (req: AuthRequest, res: Response) => {
  const userId = req.userId as number;

  const sql = `
    SELECT
      COUNT(*) AS total_rides,
      SUM(CASE WHEN source = 'driver' THEN 1 ELSE 0 END) AS as_driver,
      SUM(CASE WHEN source = 'passenger' THEN 1 ELSE 0 END) AS as_passenger,
      COALESCE(SUM(distance_km), 0) AS km_shared,
      (COALESCE(SUM(distance_km), 0) * 0.12) AS co2_saved
    FROM (
      SELECT r.id, r.distance_km, 'driver' AS source
      FROM rides r
      WHERE r.driver_user_id = ?

      UNION ALL

      SELECT r.id, r.distance_km, 'passenger' AS source
      FROM rides r
      INNER JOIN ride_passengers rp ON rp.ride_id = r.id
      WHERE rp.user_id = ? AND rp.status = 'joined'
    ) my_rides
  `;

  db.get(sql, [userId, userId], (err: DbError, row: DbRow) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }

    res.json(row);
  });
});

app.get('/stats/me/weekly', requireAuth, (req: AuthRequest, res: Response) => {
  const userId = req.userId as number;
  const sql = `
    SELECT day_key, COALESCE(SUM(distance_km), 0) AS km
    FROM (
      SELECT DATE(r.depart_time) AS day_key, r.distance_km
      FROM rides r
      WHERE r.driver_user_id = ?

      UNION ALL

      SELECT DATE(r.depart_time) AS day_key, r.distance_km
      FROM rides r
      INNER JOIN ride_passengers rp ON rp.ride_id = r.id
      WHERE rp.user_id = ? AND rp.status = 'joined'
    ) t
    WHERE day_key >= DATE('now', '-6 day')
    GROUP BY day_key
    ORDER BY day_key ASC
  `;

  db.all(sql, [userId, userId], (err: DbError, rows: DbRows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// --- USER ENDPOINTS ---
app.get('/users', (_req: Request, res: Response): void => {
  db.all(`SELECT ${userSelectFields} FROM users ORDER BY id ASC`, [], (err: DbError, rows: DbRows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.post('/users', async (req: Request, res: Response): Promise<void> => {
  // Legacy-compatible endpoint: if password exists use it, otherwise default dev password.
  const { name, email, password } = req.body as { name?: string; email?: string; password?: string };
  const safeName = (name ?? '').trim();
  const safeEmail = (email ?? '').trim().toLowerCase();

  if (!safeName || !safeEmail) {
    res.status(400).json({ error: 'Name und Email sind Pflichtfelder.' });
    return;
  }

  const rawPassword = (password ?? 'Passwort123!').trim();
  if (rawPassword.length < 8) {
    res.status(400).json({ error: 'Passwort muss mindestens 8 Zeichen haben.' });
    return;
  }

  const hash = await bcrypt.hash(rawPassword, 10);

  db.run(`INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)`, [safeName, safeEmail, hash], function (this: sqlite3.RunResult, err: DbError) {
    if (err) {
      if (err.message.includes('UNIQUE')) {
        res.status(400).json({ error: 'Email existiert bereits.' });
        return;
      }
      res.status(500).json({ error: err.message });
      return;
    }

    res.status(201).json({ id: this.lastID, name: safeName, email: safeEmail });
  });
});

app.get('/users/:id', (req: Request, res: Response) => {
  const userId = Number(req.params.id);
  if (!userId) {
    res.status(400).json({ error: 'Ungültige Benutzer-ID.' });
    return;
  }

  db.get(`SELECT ${userSelectFields} FROM users WHERE id = ?`, [userId], (err: DbError, row: DbRow) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: 'Benutzer nicht gefunden.' });
    res.json(row);
  });
});

app.patch('/users/me', requireAuth, (req: AuthRequest, res: Response): void => {
  const { name } = req.body as { name?: string };
  const safeName = (name ?? '').trim();
  if (!safeName) {
    res.status(400).json({ error: 'Name ist erforderlich.' });
    return;
  }

  db.run(`UPDATE users SET name = ? WHERE id = ?`, [safeName, req.userId], function (this: sqlite3.RunResult, err: DbError) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (this.changes === 0) {
      res.status(404).json({ error: 'Benutzer nicht gefunden.' });
      return;
    }

    db.get(`SELECT ${userSelectFields} FROM users WHERE id = ?`, [req.userId], (fetchErr: DbError, row: DbRow) => {
      if (fetchErr) {
        res.status(500).json({ error: fetchErr.message });
        return;
      }
      res.json(row);
    });
  });
});

// --- GROUP ENDPOINTS ---
app.get('/groups', (req: AuthRequest, res: Response): void => {
  const userId = resolveUserId(req);
  if (!userId) {
    res.status(400).json({ error: 'user_id ist erforderlich.' });
    return;
  }

  const sql = `
    SELECT
      g.id,
      g.name,
      g.code,
      g.owner_user_id,
      (SELECT COUNT(*) FROM group_members gm2 WHERE gm2.group_id = g.id) AS members_count,
      CASE WHEN g.owner_user_id = ? THEN 1 ELSE 0 END AS is_owner,
      gm.role as current_user_role
    FROM groups g
    INNER JOIN group_members gm ON gm.group_id = g.id AND gm.user_id = ?
    ORDER BY g.created_at DESC
  `;

  db.all(sql, [userId, userId], (err: DbError, rows: DbRows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/groups', (req: AuthRequest, res: Response): void => {
  const { name, user_id } = req.body;
  const ownerUserId = req.userId ?? Number(user_id);
  const groupName = (name ?? '').toString().trim();

  if (!ownerUserId || !groupName) {
    res.status(400).json({ error: 'name und user_id sind Pflichtfelder.' });
    return;
  }

  const createWithCode = (triesLeft: number) => {
    if (triesLeft <= 0) {
      res.status(500).json({ error: 'Konnte keinen eindeutigen Gruppencode erzeugen.' });
      return;
    }

    const code = randomGroupCode();
    db.run(
      `INSERT INTO groups (name, code, owner_user_id) VALUES (?, ?, ?)` ,
      [groupName, code, ownerUserId],
      function (this: sqlite3.RunResult, err: DbError) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            createWithCode(triesLeft - 1);
            return;
          }
          res.status(500).json({ error: err.message });
          return;
        }

        const groupId = this.lastID;
        db.run(
          `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'admin')`,
          [groupId, ownerUserId],
          (memberErr: DbError) => {
            if (memberErr) {
              res.status(500).json({ error: memberErr.message });
              return;
            }

            db.get(selectGroupForUserSql, [ownerUserId, ownerUserId, groupId], (selectErr: DbError, row: DbRow) => {
              if (selectErr) return res.status(500).json({ error: selectErr.message });
              res.status(201).json(row);
            });
          },
        );
      },
    );
  };

  createWithCode(10);
});

app.post('/groups/join', (req: AuthRequest, res: Response): void => {
  const { code, user_id } = req.body;
  const userId = req.userId ?? Number(user_id);
  const groupCode = (code ?? '').toString().trim().toUpperCase();

  if (!userId || !groupCode) {
    res.status(400).json({ error: 'code und user_id sind Pflichtfelder.' });
    return;
  }

  db.get(`SELECT id FROM groups WHERE code = ?`, [groupCode], (groupErr: DbError, groupRow: any) => {
    if (groupErr) return res.status(500).json({ error: groupErr.message });
    if (!groupRow) {
      res.status(404).json({ error: 'Gruppe nicht gefunden.' });
      return;
    }

    const groupId = Number(groupRow.id);
    db.run(
      `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')`,
      [groupId, userId],
      (memberErr: DbError) => {
        if (memberErr && !memberErr.message.includes('UNIQUE')) {
          res.status(500).json({ error: memberErr.message });
          return;
        }

        db.get(selectGroupForUserSql, [userId, userId, groupId], (selectErr: DbError, row: DbRow) => {
          if (selectErr) return res.status(500).json({ error: selectErr.message });
          res.status(200).json(row);
        });
      },
    );
  });
});

app.post('/groups/:id/leave', (req: AuthRequest, res: Response): void => {
  const groupId = Number(req.params.id);
  const userId = req.userId ?? Number(req.body.user_id);

  if (!groupId || !userId) {
    res.status(400).json({ error: 'group_id und user_id sind Pflichtfelder.' });
    return;
  }

  db.get(`SELECT owner_user_id FROM groups WHERE id = ?`, [groupId], (groupErr: DbError, groupRow: any) => {
    if (groupErr) return res.status(500).json({ error: groupErr.message });
    if (!groupRow) {
      res.status(404).json({ error: 'Gruppe nicht gefunden.' });
      return;
    }

    const ownerUserId = Number(groupRow.owner_user_id);
    if (ownerUserId === userId) {
      db.run(`DELETE FROM group_members WHERE group_id = ?`, [groupId], (memberErr: DbError) => {
        if (memberErr) return res.status(500).json({ error: memberErr.message });
        db.run(`DELETE FROM groups WHERE id = ?`, [groupId], function (_this: sqlite3.RunResult, deleteErr: DbError) {
          if (deleteErr) return res.status(500).json({ error: deleteErr.message });
          res.json({ deleted_group: true, message: 'Eigene Gruppe gelöscht.' });
        });
      });
      return;
    }

    db.run(
      `DELETE FROM group_members WHERE group_id = ? AND user_id = ?`,
      [groupId, userId],
      function (this: sqlite3.RunResult, leaveErr: DbError) {
        if (leaveErr) return res.status(500).json({ error: leaveErr.message });
        if (this.changes === 0) {
          res.status(404).json({ error: 'Mitgliedschaft nicht gefunden.' });
          return;
        }
        res.json({ deleted_group: false, message: 'Gruppe verlassen.' });
      },
    );
  });
});

app.listen(port, () => {
  console.log(`RideLog Backend läuft auf http://localhost:${port}`);
});
