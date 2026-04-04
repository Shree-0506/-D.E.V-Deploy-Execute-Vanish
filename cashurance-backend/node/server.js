const express = require('express');
const cors = require('cors');
const authRoutes = require('./src/routes/authRoutes');
const appRoutes = require('./src/routes/appRoutes');
const adminRoutes = require('./src/routes/adminRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
const corsOptions = {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false
};
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/app', appRoutes);
app.use('/api/v1/admin', adminRoutes);

app.get('/health', (req, res) => {
    console.log('Health check requested from:', req.ip);
    res.json({ success: true, status: 'ok' });
});

// Base route for health check
app.get('/', (req, res) => {
    res.json({ status: 'CashUrance Registration Backend is running.' });
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is listening on port ${PORT}`);
});
