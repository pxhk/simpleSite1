import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [systemInfo, setSystemInfo] = useState({
    hostname: 'Loading...',
    ipAddress: 'Loading...'
  });
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchSystemInfo = async () => {
      try {
        const response = await axios.get('/api/system-info');
        console.log('API Response:', response.data);
        setSystemInfo(response.data);
        setError(null);
      } catch (error) {
        console.error('Error fetching system info:', error);
        setSystemInfo({
          hostname: 'Error loading hostname',
          ipAddress: 'Error loading IP'
        });
        setError(error.message);
      }
    };

    fetchSystemInfo();
    
    const interval = setInterval(fetchSystemInfo, 30000);
    
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Hello World!</h1>
        <div className="info-container">
          <div className="info-card">
            <h2>System Information</h2>
            <p>Hostname: {systemInfo.hostname}</p>
            <p>IP Address: {systemInfo.ipAddress}</p>
            {error && (
              <p className="error-message" style={{ color: '#ff6b6b' }}>
                Error: {error}
              </p>
            )}
          </div>
        </div>
      </header>
    </div>
  );
}

export default App;
