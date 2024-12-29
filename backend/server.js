const express = require('express');
const cors = require('cors');
const os = require('os');

const app = express();

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Add logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

app.get('/api/system-info', (req, res) => {
    try {
        console.log('Getting system info...');
        const hostname = os.hostname();
        const networkInterfaces = os.networkInterfaces();
        let ipAddress = 'localhost';
        
        console.log('Network interfaces:', networkInterfaces);
        
        // Get the first non-internal IPv4 address
        Object.keys(networkInterfaces).forEach((interfaceName) => {
            networkInterfaces[interfaceName].forEach((interface) => {
                if (interface.family === 'IPv4' && !interface.internal) {
                    ipAddress = interface.address;
                }
            });
        });

        console.log(`Hostname: ${hostname}, IP: ${ipAddress}`);
        
        res.json({
            hostname,
            ipAddress
        });
    } catch (error) {
        console.error('Error in /api/system-info:', error);
        res.status(500).json({ 
            error: 'Failed to get system information',
            details: error.message 
        });
    }
});

// Add a health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log('Server configuration:');
    console.log(`- Port: ${PORT}`);
    console.log(`- Node version: ${process.version}`);
    console.log(`- Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Handle errors
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});

process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
});
