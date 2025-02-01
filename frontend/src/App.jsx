import { useState, useEffect } from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  TimeScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import 'chartjs-adapter-date-fns';
import './App.css';

ChartJS.register(
  CategoryScale,
  TimeScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

function App() {
  const [dataPoints, setDataPoints] = useState([]);

  // Fetch new metric every 30 seconds
  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    try {
      const res = await fetch('http://localhost:3001/api/metrics');
      if (!res.ok) {
        throw new Error('Network response was not ok');
      }
      const metric = await res.json();
      setDataPoints(prev => {
        // Append new metric; if more than 100 entries, remove the first (oldest)
        const updated = [...prev, metric];
        if (updated.length > 100) {
          updated.shift();
        }
        return updated;
      });
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };

  // Prepare chart labels from the "timestamp" values
  const labels = dataPoints.map(point => new Date(point.timestamp));

  // Determine which metric keys to show (excluding non-numeric ones)
  // You can customize this list (for example, focusing only on selected metrics)
  const metricKeys = dataPoints.length > 0
    ? Object.keys(dataPoints[0]).filter(key =>
        key !== "timestamp" &&
        key !== "createdAt" &&
        typeof dataPoints[0][key] === 'number'
      )
    : [];

  const datasets = metricKeys.map((key, index) => {
    // Generate a color for each metric line
    const color = `hsl(${(index * 60) % 360}, 70%, 50%)`;
    return {
      label: key,
      data: dataPoints.map(point => point[key]),
      borderColor: color,
      backgroundColor: color,
      fill: false,
    };
  });

  const chartData = {
    labels,
    datasets,
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Metrics over Time',
      },
    },
    scales: {
      x: {
        type: 'time',
        time: {
          unit: 'second'
        }
      }
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>Metrics Dashboard</h1>
      <Line data={chartData} options={options} />
    </div>
  );
}

export default App;
