import express, { Request, Response } from 'express'; 
import db, { initDB } from './database';
import bodyParser from 'body-parser'; 

const app = express();
const port = 3000; 

app.use(express.json());
app.use(bodyParser.json()); 
app.use(express.urlencoded({ extended: true }));

initDB();

// --- RIDE ENDPOINTS ---
// 1. Alle Fahrten abrufen
app.get('/rides', (req: Request, res: Response) => {
    db.all('SELECT * FROM rides', [], (err, rows) => { 
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

app.listen(port, () => { 
    console.log(`RideLog Backend läuft auf http://localhost:${port}`);
});