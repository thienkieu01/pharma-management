// server.js
const express = require('express');
const mysql   = require('mysql2/promise');
const path    = require('path');
const app     = express();

// ---------- 1. KẾT NỐI DB (đã có) ----------
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',          // <-- thay nếu khác
    password: '',          // <-- thay nếu có
    database: 'pharmacy_db',
    waitForConnections: true,
    connectionLimit: 10
});

// ---------- 2. CÀI ĐẶT ----------
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));   // nếu có CSS/JS

// ---------- 3. ROUTE CHÍNH (3.2 – LIST + SEARCH) ----------
app.get('/', async (req, res) => {
    const { search = '', minAge = '', sort = 'FullName' } = req.query;
    try {
        const [rows] = await pool.execute(
            `EXEC GetCustomers @SearchName = ?, @MinAge = ?, @SortBy = ?`,
            [search || null, minAge || null, sort]
        );
        res.render('index', { customers: rows, search, minAge, sort });
    } catch (e) { res.send('Lỗi SQL: ' + e.message); }
});

// ---------- 4. CRUD (3.1) ----------
app.post('/add', async (req, res) => {
    const { FullName, Email, Phone, Birthdate, Gender, Address } = req.body;
    try {
        await pool.execute(
            `EXEC InsertCustomer ?, ?, ?, ?, ?, ?`,
            [FullName, Email, Phone, Birthdate, Gender, Address||null]
        );
        res.redirect('/?msg=Thêm+thành+công');
    } catch (e) { res.send('Lỗi: ' + e.message); }
});

app.post('/update', async (req, res) => {
    const { CustomerID, FullName, Email, Phone, Birthdate, Gender, Address } = req.body;
    try {
        await pool.execute(
            `EXEC UpdateCustomer ?, ?, ?, ?, ?, ?, ?`,
            [CustomerID, FullName, Email, Phone, Birthdate, Gender, Address||null]
        );
        res.redirect('/?msg=Cập+nhật+OK');
    } catch (e) { res.send('Lỗi: ' + e.message); }
});

app.post('/delete', async (req, res) => {
    try {
        await pool.execute(`EXEC DeleteCustomer ?`, [req.body.id]);
        res.redirect('/?msg=Xóa+thành+công');
    } catch (e) { res.send('Lỗi: ' + e.message); }
});

// 3.2
app.get('/customer/list', async (req, res) => {
  const phoneSearch = req.query.phone || ''; // Nếu có tìm kiếm theo số điện thoại
  let query = '';
  let params = [];

  if (phoneSearch) {
    query = `SELECT * FROM Customers WHERE Phone LIKE ?`;
    params = [`%${phoneSearch}%`];
  } else {
    query = `SELECT * FROM Customers`; // Lấy tất cả khách hàng
  }

  try {
    const [customers] = await pool.execute(query, params);

    res.render('customer-list', {
      customers,
      phoneSearch,
      success: req.query.success || null,
      error: req.query.error || null,
      showLoyalTab: false // mặc định mở tab search
    });
  } catch (err) {
    res.render('customer-list', {
      customers: [],
      phoneSearch,
      success: null,
      error: 'Lỗi SQL: ' + err.message,
      showLoyalTab: false
    });
  }
});


// ---------- 5. BÁO CÁO (3.3) ----------
app.get('/report', async (req, res) => {
    const { from, to } = req.query;
    try {
        const [rows] = await pool.execute(
            `EXEC GetCustomerRevenue ?, ?`,
            [from || null, to || null]
        );
        res.render('report', { data: rows, from, to });
    } catch (e) { res.send('Lỗi: ' + e.message); }
});

// ---------- 6. KHỞI ĐỘNG ----------
const PORT = 3000;
app.listen(PORT, () => console.log(`http://localhost:${PORT}`));