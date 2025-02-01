import express from 'express';
import { MongoClient } from 'mongodb';
import cors from 'cors';

const app = express();
const port = 3001;

// Enable CORS in case the frontend is served from a different origin
app.use(cors());
app.use(express.json());

const uri = "mongodb://adminuser:password123@138.2.46.52:32001";
const client = new MongoClient(uri, { useUnifiedTopology: true });

async function run() {
  try {
    await client.connect();
    console.log("Connected to MongoDB");
    const db = client.db('voyeur');
    const collection = db.collection('ty_backend_metrics');

    // Retrieves the latest metric (based on the "timestamp" field)
    app.get('/api/metrics', async (req, res) => {
      try {
        const metric = await collection.find().sort({ "timestamp": -1 }).limit(1).toArray();
        if (metric.length === 0) {
          return res.status(404).json({ message: "No metric found" });
        }
        res.json(metric[0]);
      } catch (error) {
        console.error("Error fetching metric:", error);
        res.status(500).json({ error: "Internal Server Error" });
      }
    });

    app.listen(port, () => {
      console.log(`Server is running on port ${port}`);
    });
  } catch (error) {
    console.error("Error connecting to MongoDB:", error);
  }
}

run().catch(console.dir); 