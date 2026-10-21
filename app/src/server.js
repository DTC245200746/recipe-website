const express = require('express');
const path = require('path');
const pool = require('./db');

const app = express();
const wrap = fn => (req, res, next) => fn(req, res, next).catch(next);

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../views'));
app.set('trust proxy', 1);
app.use(express.urlencoded({ extended: false }));
app.use('/static', express.static(path.join(__dirname, '../public')));

app.get('/health', wrap(async (req, res) => {
  await pool.query('SELECT 1');
  res.json({ status: 'ok' });
}));

app.get('/', wrap(async (req, res) => {
  const { q = '', category = '' } = req.query;
  let sql = `SELECT r.*, c.name AS category FROM recipes r
             JOIN categories c ON c.id = r.category_id WHERE 1=1`;
  const params = [];
  if (q) { sql += ' AND r.title LIKE ?'; params.push(`%${q}%`); }
  if (category) { sql += ' AND c.id = ?'; params.push(category); }
  sql += ' ORDER BY r.created_at DESC';
  const [recipes] = await pool.query(sql, params);
  const [categories] = await pool.query('SELECT * FROM categories ORDER BY name');
  res.render('index', { recipes, categories, q, category });
}));

app.get('/recipes/new', wrap(async (req, res) => {
  const [categories] = await pool.query('SELECT * FROM categories ORDER BY name');
  res.render('new', { categories });
}));

app.post('/recipes', wrap(async (req, res) => {
  const { title, description, instructions, category_id, ingredients = '' } = req.body;
  if (!title || !instructions || !category_id) return res.status(400).send('Thiếu dữ liệu bắt buộc');
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [r] = await conn.query(
      'INSERT INTO recipes (title, description, instructions, category_id) VALUES (?,?,?,?)',
      [title.trim(), description || '', instructions, category_id]);
    const rows = ingredients.split('\n').map(l => l.trim()).filter(Boolean).map(l => {
      const [n, q = ''] = l.split('|');
      return [r.insertId, n.trim(), q.trim()];
    });
    if (rows.length) await conn.query('INSERT INTO ingredients (recipe_id, name, quantity) VALUES ?', [rows]);
    await conn.commit();
    res.redirect(`/recipes/${r.insertId}`);
  } catch (e) { await conn.rollback(); throw e; } finally { conn.release(); }
}));

app.get('/recipes/:id', wrap(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT r.*, c.name AS category FROM recipes r
     JOIN categories c ON c.id = r.category_id WHERE r.id = ?`, [req.params.id]);
  if (!rows.length) return res.status(404).send('Không tìm thấy công thức');
  const [ingredients] = await pool.query('SELECT * FROM ingredients WHERE recipe_id = ?', [req.params.id]);
  res.render('recipe', { recipe: rows[0], ingredients });
}));

app.use((err, req, res, next) => {
  console.error(`[ERROR] ${req.method} ${req.url} - ${err.message}`);
  res.status(500).send('Lỗi máy chủ');
});

app.listen(3000, () => console.log('Recipe app listening on :3000'));
