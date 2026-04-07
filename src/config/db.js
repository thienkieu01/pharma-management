// config/db.js
const sql = require('mssql');

const config = {
  server: 'localhost\\SQLEXPRESS', 
  authentication: {
    type: 'default',
    options: {
      userName: 'nodeuser',
      password: '123456'
    }
  },
  options: {
    database: 'BTL_Restore3',
    trustServerCertificate: true,
    encrypt: false,
    enableArithAbort: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

console.log("Đang kết nối SQL Server bằng SQL Authentication…");

// Tạo pool kết nối
const poolPromise = new sql.ConnectionPool(config)
  .connect()
  .then(pool => {
    console.log("Kết nối CSDL thành công!");
    return pool;
  })
  .catch(err => {
    console.log("Lỗi kết nối CSDL: ", err.message);
    process.exit(1); // Dừng server nếu không kết nối được
  });

module.exports = { sql, poolPromise };