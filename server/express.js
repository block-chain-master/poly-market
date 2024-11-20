import express from 'express';
import cors from 'cors';
import { scrapePolymarket } from './scraper.js';

const app = express();
app.use(cors());

app.get('/api/polymarket-data', async (req, res) => {
    try {
        const data = await scrapePolymarket();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Scraping failed' });
    }
});

app.listen(3000, () => console.log('Server running on port 3000'));
