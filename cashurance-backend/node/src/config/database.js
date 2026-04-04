const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, '../../database.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database', err);
    } else {
        console.log('Connected to the SQLite database.');

        db.run(`CREATE TABLE IF NOT EXISTS workers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT,
            phone TEXT UNIQUE,
            password_hash TEXT,
            dob TEXT,
            address TEXT,
            pincode TEXT,
            id_front_path TEXT,
            id_back_path TEXT,
            platform TEXT,
            platform_worker_id TEXT,
            upi_id TEXT,
            status TEXT,
            zone_name TEXT DEFAULT '',
            zone_confirmed INTEGER DEFAULT 0,
            online_today INTEGER DEFAULT 1,
            policy_start TEXT,
            policy_premium REAL,
            last_payment_at TEXT,
            next_payment_due_at TEXT,
            avg_daily_income REAL DEFAULT 1200,
            policies_purchased INTEGER DEFAULT 0,
            payouts_settled INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`, (err) => {
            if (err) {
                console.error("Error creating table", err);
            } else {
                console.log("Table 'workers' is ready.");
                runMigrations();
            }
        });
    }
});

function runMigrations() {
    const requiredColumns = [
        { name: 'password_hash', type: 'TEXT' },
        { name: 'zone_name', type: "TEXT DEFAULT ''" },
        { name: 'zone_confirmed', type: 'INTEGER DEFAULT 0' },
        { name: 'online_today', type: 'INTEGER DEFAULT 1' },
        { name: 'policy_start', type: 'TEXT' },
        { name: 'policy_premium', type: 'REAL' },
        { name: 'last_payment_at', type: 'TEXT' },
        { name: 'next_payment_due_at', type: 'TEXT' },
        { name: 'avg_daily_income', type: 'REAL DEFAULT 1200' },
        { name: 'policies_purchased', type: 'INTEGER DEFAULT 0' },
        { name: 'payouts_settled', type: 'INTEGER DEFAULT 0' },
        { name: 'notif_event_alerts', type: 'INTEGER DEFAULT 1' },
        { name: 'notif_weekly_reminders', type: 'INTEGER DEFAULT 1' },
        { name: 'notif_payout_updates', type: 'INTEGER DEFAULT 1' },
        { name: 'zone_latitude', type: 'REAL DEFAULT 12.9716' },
        { name: 'zone_longitude', type: 'REAL DEFAULT 77.5946' },
    ];

    db.all('PRAGMA table_info(workers)', (err, rows) => {
        if (err) {
            console.error('Error reading workers table info', err);
            return;
        }

        const existing = new Set(rows.map((row) => row.name));
        requiredColumns.forEach((column) => {
            if (!existing.has(column.name)) {
                db.run(`ALTER TABLE workers ADD COLUMN ${column.name} ${column.type}`, (alterErr) => {
                    if (alterErr) {
                        console.error(`Error adding column ${column.name}`, alterErr);
                    } else {
                        console.log(`Column '${column.name}' is ready.`);
                    }
                });
            }
        });

        db.run(
            `UPDATE workers
             SET status = 'SUSPENDED'
             WHERE UPPER(COALESCE(status, '')) = 'BANNED'`,
            (statusErr) => {
                if (statusErr) {
                    console.error('Error normalizing worker status values', statusErr);
                }
            },
        );

        db.run(
            `UPDATE workers
             SET zone_name = '', zone_latitude = NULL, zone_longitude = NULL
             WHERE COALESCE(zone_confirmed, 0) = 0
               AND COALESCE(TRIM(zone_name), '') = 'Koramangala, Bengaluru'`,
            (zoneCleanupErr) => {
                if (zoneCleanupErr) {
                    console.error('Error cleaning default onboarding zone values', zoneCleanupErr);
                }
            },
        );

        db.serialize(() => {
            db.run(
                `CREATE TABLE IF NOT EXISTS activity_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    worker_id INTEGER,
                    event_type TEXT NOT NULL,
                    metadata TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (worker_id) REFERENCES workers(id)
                )`,
                (activityErr) => {
                    if (activityErr) {
                        console.error('Error creating table activity_logs', activityErr);
                    }
                },
            );

            db.run(
                'CREATE INDEX IF NOT EXISTS idx_activity_logs_worker_time ON activity_logs(worker_id, created_at DESC)',
                (activityIndexErr) => {
                    if (activityIndexErr) {
                        console.error('Error creating activity_logs index', activityIndexErr);
                    }
                },
            );

            db.run(
                `CREATE TABLE IF NOT EXISTS admin_audit_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    admin_email TEXT NOT NULL,
                    action_type TEXT NOT NULL,
                    worker_id INTEGER,
                    status TEXT,
                    reason TEXT,
                    ref_id TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (worker_id) REFERENCES workers(id)
                )`,
                (auditErr) => {
                    if (auditErr) {
                        console.error('Error creating table admin_audit_logs', auditErr);
                    }
                },
            );

            db.run(
                'CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_worker_time ON admin_audit_logs(worker_id, created_at DESC)',
                (auditIndexErr) => {
                    if (auditIndexErr) {
                        console.error('Error creating admin_audit_logs index', auditIndexErr);
                    }
                },
            );
        });
    });
}

module.exports = db;
