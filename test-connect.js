const { Connection } = require('tedious');

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
    trustServerCertificate: true,
    database: 'BTL_Restore1'
  }
};

console.log("Kết nối SQL bằng SQL Authentication…");

const connection = new Connection(config);

connection.on('connect', err => {
  if (err) console.log("❌", err.message);
  else console.log("✅ Kết nối thành công!");
  
  connection.close();
});

connection.connect();
