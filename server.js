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
});