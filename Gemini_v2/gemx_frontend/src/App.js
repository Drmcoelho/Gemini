import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [automations, setAutomations] = useState([]);
  const [selectedAutomation, setSelectedAutomation] = useState(null);
  const [prompt, setPrompt] = useState('');
  const [output, setOutput] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const API_BASE_URL = 'http://localhost:8000'; // Assuming FastAPI is running on port 8000

  useEffect(() => {
    // Fetch list of automations from the backend
    const fetchAutomations = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/automations`);
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setAutomations(data.automations);
      } catch (e) {
        setError(`Failed to fetch automations: ${e.message}`);
        console.error("Failed to fetch automations:", e);
      }
    };

    fetchAutomations();
  }, []);

  const handleRunAutomation = async () => {
    if (!selectedAutomation || !prompt) {
      setError("Please select an automation and enter a prompt.");
      return;
    }

    setLoading(true);
    setError('');
    setOutput('');

    try {
      const response = await fetch(`${API_BASE_URL}/automations/run`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          automation_name: selectedAutomation,
          prompt: prompt,
          extra_args: [], // Add any extra args if needed
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setOutput(data.output);
    } catch (e) {
      setError(`Failed to run automation: ${e.message}`);
      console.error("Failed to run automation:", e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Gemini Megapack v2 Web Interface</h1>
      </header>
      <div className="App-container">
        <nav className="App-nav">
          <h2>Automations</h2>
          {error && <p className="error-message">{error}</p>}
          <ul>
            {automations.map((auto) => (
              <li
                key={auto}
                className={selectedAutomation === auto ? 'selected' : ''}
                onClick={() => {
                  setSelectedAutomation(auto);
                  setError('');
                  setOutput('');
                }}
              >
                {auto}
              </li>
            ))}
          </ul>
        </nav>
        <main className="App-main">
          {selectedAutomation ? (
            <div>
              <h2>Run: {selectedAutomation}</h2>
              <textarea
                placeholder="Enter your prompt here..."
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                rows="10"
                cols="80"
              ></textarea>
              <button onClick={handleRunAutomation} disabled={loading}>
                {loading ? 'Running...' : 'Run Automation'}
              </button>
              {output && (
                <div className="App-output">
                  <h3>Output:</h3>
                  <pre>{output}</pre>
                </div>
              )}
            </div>
          ) : (
            <p>Select an automation from the menu.</p>
          )}
        </main>
      </div>
    </div>
  );
}

export default App;