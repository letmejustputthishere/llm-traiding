import { useState, useEffect } from "react";
import ReactDOM from "react-dom/client";
import { backend } from "declarations/backend";

// Simple log display component
const App = () => {
    // State to hold array of logs
    const [logs, setLogs] = useState([]);

    // Poll backend.getLogs() every 2 seconds and replace logs state
    useEffect(() => {
        const fetchLogs = async () => {
            try {
                const result = await backend.getLogs();
                // Ensure we have an array of log entries
                const entries = Array.isArray(result)
                    ? result
                    : result.split("\n\n");
                setLogs(entries);
            } catch (err) {
                console.error("Failed to fetch logs:", err);
            }
        };

        fetchLogs(); // initial fetch
        const intervalId = setInterval(fetchLogs, 2000);
        return () => clearInterval(intervalId);
    }, []);

    return (
        <div style={{ padding: "1rem", fontFamily: "sans-serif" }}>
            <h1>System Logs</h1>
            <pre
                style={{
                    whiteSpace: "pre-wrap",
                    background: "#f5f5f5",
                    padding: "1rem",
                }}
            >
                {logs.join("\n")}
            </pre>
        </div>
    );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
