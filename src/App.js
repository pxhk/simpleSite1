import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [systemInfo, setSystemInfo] = useState({
    hostname: 'Loading...',
    ipAddress: 'Loading...'
  });

  useEffect(() => {
    const fetchSystemInfo = async () => {
      try {
        const response = await axios.get('http://localhost:5000/api/system-info');
        setSystemInfo(response.data);
      } catch (error) {
        console.error('Error fetching system info:', error);
        setSystemInfo({
          hostname: 'Error loading hostname',
          ipAddress: 'Error loading IP'
        });
      }
    };

    fetchSystemInfo();
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
          </div>
        </div>
      </header>
    </div>
  );
}

export default App;
