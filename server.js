<<<<<<< HEAD
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
const PORT = process.env.PORT || 10000;

// Middleware
app.use(cors());
app.use(express.json());

// Проверка, что сервер жив
app.get('/', (req, res) => {
    res.json({ message: 'MicroBlog backend is running!' });
});

// GET /posts — получить все посты
app.get('/posts', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM posts ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /posts — добавить новый пост
app.post('/posts', async (req, res) => {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: 'text is required' });

    try {
        const result = await pool.query(
            'INSERT INTO posts (text) VALUES ($1) RETURNING *',
            [text]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
=======
// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
const PORT = process.env.PORT || 10000;

// Middleware
app.use(cors());            // разрешаем запросы с frontend
app.use(express.json());    // читаем JSON из тела запроса

// Проверка, что сервер жив
app.get('/', (req, res) => {
    res.json({ message: 'MicroBlog backend is running!' });
});

// Пример маршрута: получить все посты
app.get('/posts', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM posts ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
>>>>>>> 61d4660f6214e7013315d5711f5f554e6ed521b1
});