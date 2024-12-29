const express = require('express');
const cors = require('cors');
const os = require('os');

const app = express();
app.use(cors());

app.get('/api/system-info', (req, res) => {
    const hostname = os.hostname();
    const networkInterfaces = os.networkInterfaces();
    let ipAddress = 'localhost';
    
    // Get the first non-internal IPv4 address
    Object.keys(networkInterfaces).forEach((interfaceName) => {
        networkInterfaces[interfaceName].forEach((interface) => {
            if (interface.family === 'IPv4' && !interface.internal) {
                ipAddress = interface.address;
            }
        });
    });

    res.json({
        hostname,
        ipAddress
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
