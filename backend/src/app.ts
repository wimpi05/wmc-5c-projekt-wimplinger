import express, { Request, Response } from 'express'; 
import db, { initDB } from './database';
import bodyParser from 'body-parser'; 

const app = express();
const port = 3000; 

app.use(express.json());
app.use(bodyParser.json()); 
app.use(express.urlencoded({ extended: true }));

initDB();

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

// --- RIDE ENDPOINTS ---
// 1. Alle Fahrten abrufen
app.get('/rides', (req: Request, res: Response) => {
    const sql = `
        SELECT 
            r.*, 
            u.name as driver_username,
            -- Hier zählen wir nur die Passagiere, die wirklich 'joined' sind
            (SELECT COUNT(*) 
             FROM ride_passengers rp 
             WHERE rp.ride_id = r.id 
             AND rp.status = 'joined') as seats_occupied
        FROM rides r
        LEFT JOIN users u ON r.driver_user_id = u.id
        ORDER BY r.depart_time ASC
    `;
    
    db.all(sql, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// 2. Neue Fahrt erstellen
app.post('/rides', (req: Request, res: Response) => {
    const { driver_user_id, start_name, end_name, depart_time, seats_total, price_per_seat, distance_km, note } = req.body;
    const sql = `INSERT INTO rides (driver_user_id, start_name, end_name, depart_time, seats_total, price_per_seat, distance_km, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
    
    db.run(sql, [driver_user_id, start_name, end_name, depart_time, seats_total, price_per_seat, distance_km, note], function(err) { 
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID });
    });
});

// 3. Einer Fahrt beitreten 
app.post('/rides/:id/join', (req: Request, res: Response) => {
    const rideId = req.params.id;
    const { user_id } = req.body;
    
    const sql = `INSERT INTO ride_passengers (ride_id, user_id, status) VALUES (?, ?, 'joined')`;
    
    db.run(sql, [rideId, user_id], function(err) {
        if (err) {
            return res.status(500).json({ error: "Beitritt fehlgeschlagen oder bereits angemeldet." });
        }
        // Rückgabe der passenger_id (this.lastID) für das Flutter-Model
        res.status(201).json({ 
            passenger_id: this.lastID, 
            ride_id: parseInt(rideId),
            user_id: user_id,
            status: 'joined'
        });
    });
});
// 4. Fahrt absagen 
app.post('/rides/:id/cancel', (req: Request, res: Response) => {
    const rideId = req.params.id;
    const { user_id } = req.body;
    
    const sql = `UPDATE ride_passengers SET status = 'cancelled' WHERE ride_id = ? AND user_id = ?`;
    
    db.run(sql, [rideId, user_id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        
        if (this.changes === 0) {
            return res.status(404).json({ error: "Keine aktive Anmeldung gefunden." });
        }
        
        res.json({ message: "Cancelled successfully", status: 'cancelled' });
    });
});

// --- STATS ENDPOINT ---

// 5. Statistiken aggregieren 
app.get('/stats/rides', (req: Request, res: Response) => {
    const sql = `
        SELECT 
            COUNT(*) as totalRides, 
            SUM(distance_km) as totalKm,
            (SUM(distance_km) * 0.2) as co2Saved 
        FROM rides`; 
    db.get(sql, [], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(row); 
    });
});

// --- USER ENDPOINTS ---
// 1. Profil erstellen / Benutzer registrieren
app.post('/users', (req: Request, res: Response): void => {
    const { name, email } = req.body;

    if (!name || !email) {
        res.status(400).json({ error: "Name und Email sind Pflichtfelder." });
        return; 
    }
    const sql = `INSERT INTO users (name, email) VALUES (?, ?)`;
    db.run(sql, [name, email], function(err) {
        if (err) {
            if (err.message.includes("UNIQUE")) {
                res.status(400).json({ error: "Email existiert bereits." });
                return;
            }
            res.status(500).json({ error: err.message });
            return;
        }
        res.status(201).json({ 
            id: this.lastID, 
            name, 
            email 
        });
    });
});

// 2. Benutzerprofil abrufen
app.get('/users/:id', (req: Request, res: Response) => {
    const userId = req.params.id;
    db.get(`SELECT * FROM users WHERE id = ?`, [userId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!row) return res.status(404).json({ error: "Benutzer nicht gefunden." });
        res.json(row);
    });
});

// --- GROUP ENDPOINTS ---
app.get('/groups', (req: Request, res: Response): void => {
    const userId = Number(req.query.user_id);
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

    db.all(sql, [userId, userId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

app.post('/groups', (req: Request, res: Response): void => {
    const { name, user_id } = req.body;
    const ownerUserId = Number(user_id);
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
            function (err) {
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
                    (memberErr) => {
                        if (memberErr) {
                            res.status(500).json({ error: memberErr.message });
                            return;
                        }

                        db.get(selectGroupForUserSql, [ownerUserId, ownerUserId, groupId], (selectErr, row) => {
                            if (selectErr) return res.status(500).json({ error: selectErr.message });
                            res.status(201).json(row);
                        });
                    }
                );
            }
        );
    };

    createWithCode(10);
});

app.post('/groups/join', (req: Request, res: Response): void => {
    const { code, user_id } = req.body;
    const userId = Number(user_id);
    const groupCode = (code ?? '').toString().trim().toUpperCase();

    if (!userId || !groupCode) {
        res.status(400).json({ error: 'code und user_id sind Pflichtfelder.' });
        return;
    }

    db.get(`SELECT id FROM groups WHERE code = ?`, [groupCode], (groupErr, groupRow: any) => {
        if (groupErr) return res.status(500).json({ error: groupErr.message });
        if (!groupRow) {
            res.status(404).json({ error: 'Gruppe nicht gefunden.' });
            return;
        }

        const groupId = Number(groupRow.id);
        db.run(
            `INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, 'member')`,
            [groupId, userId],
            (memberErr) => {
                if (memberErr && !memberErr.message.includes('UNIQUE')) {
                    res.status(500).json({ error: memberErr.message });
                    return;
                }

                db.get(selectGroupForUserSql, [userId, userId, groupId], (selectErr, row) => {
                    if (selectErr) return res.status(500).json({ error: selectErr.message });
                    res.status(200).json(row);
                });
            }
        );
    });
});

app.post('/groups/:id/leave', (req: Request, res: Response): void => {
    const groupId = Number(req.params.id);
    const userId = Number(req.body.user_id);

    if (!groupId || !userId) {
        res.status(400).json({ error: 'group_id und user_id sind Pflichtfelder.' });
        return;
    }

    db.get(`SELECT owner_user_id FROM groups WHERE id = ?`, [groupId], (groupErr, groupRow: any) => {
        if (groupErr) return res.status(500).json({ error: groupErr.message });
        if (!groupRow) {
            res.status(404).json({ error: 'Gruppe nicht gefunden.' });
            return;
        }

        const ownerUserId = Number(groupRow.owner_user_id);
        if (ownerUserId === userId) {
            db.run(`DELETE FROM group_members WHERE group_id = ?`, [groupId], (memberErr) => {
                if (memberErr) return res.status(500).json({ error: memberErr.message });
                db.run(`DELETE FROM groups WHERE id = ?`, [groupId], function (deleteErr) {
                    if (deleteErr) return res.status(500).json({ error: deleteErr.message });
                    res.json({ deleted_group: true, message: 'Eigene Gruppe gelöscht.' });
                });
            });
            return;
        }

        db.run(
            `DELETE FROM group_members WHERE group_id = ? AND user_id = ?`,
            [groupId, userId],
            function (leaveErr) {
                if (leaveErr) return res.status(500).json({ error: leaveErr.message });
                if (this.changes === 0) {
                    res.status(404).json({ error: 'Mitgliedschaft nicht gefunden.' });
                    return;
                }
                res.json({ deleted_group: false, message: 'Gruppe verlassen.' });
            }
        );
    });
});

app.listen(port, () => { 
    console.log(`RideLog Backend läuft auf http://localhost:${port}`);
});