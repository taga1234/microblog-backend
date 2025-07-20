// db.js
require('dotenv').config();          // читает .env
const { Pool } = require('pg');      // библиотека для PostgreSQL

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false } // обязательно для Supabase
});

module.exports = pool;               // экспортируем, чтобы использовать в других файлах