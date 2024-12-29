import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Welcome to Our Simple Site</h1>
        <p>This is a test change for CI/CD pipeline - {new Date().toLocaleString()}</p>
        <div className="feature-box">
          <h2>✨ New Features</h2>
          <ul>
            <li>Automatic Deployments</li>
            <li>Docker Integration</li>
            <li>CI/CD Pipeline</li>
          </ul>
        </div>
      </header>
    </div>
  );
}

export default App;
