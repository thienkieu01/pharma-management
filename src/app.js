// app.js
const express = require('express');
const path = require('path');
const app = express();

// === CẤU HÌNH CƠ BẢN ===
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true })); // Đọc form POST
app.use(express.json());                        // Đọc JSON (cho AJAX xóa)
app.use(express.static('public'));              // CSS, JS

// === ROUTES ===
// PHẦN 3.1: QUẢN LÝ CUSTOMER
app.use('/customer', require('./routes/customerRouter'));
// (Các route khác: /product, /report...)

// === TRANG CHỦ ===
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nhà thuốc Vĩnh Hằng</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: "Inter", sans-serif;
}

body {
  background: linear-gradient(135deg, #e3f0ff, #e3f0ff);
  height: 100vh;
  display: flex;
  overflow: hidden;
}

/* MODERN SIDEBAR ━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
.sidebar {
  width: 80px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-right: 1px solid rgba(0, 0, 0, 0.06);
  padding: 24px 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  box-shadow: 4px 0 24px rgba(0, 0, 0, 0.04);
}

.sidebar-logo {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, #032F54, #0a5082);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  margin-bottom: 32px;
  box-shadow: 0 8px 20px rgba(3, 47, 84, 0.2);
  cursor: pointer;
  transition: all 0.3s ease;
}

.sidebar-logo:hover {
  transform: scale(1.05);
  box-shadow: 0 12px 28px rgba(3, 47, 84, 0.3);
}

.menu {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 0 16px;
}

.menu-item {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  transition: all 0.3s ease;
  position: relative;
  color: #64748b;
  font-size: 22px;
}

.menu-item::before {
  content: '';
  position: absolute;
  left: -16px;
  width: 4px;
  height: 0;
  background: #032F54;
  border-radius: 0 4px 4px 0;
  transition: height 0.3s ease;
}

.menu-item:hover {
  background: rgba(3, 47, 84, 0.08);
  color: #032F54;
  transform: translateX(2px);
}

.menu-item.active {
  background: #032F54;
  color: white;
  box-shadow: 0 8px 20px rgba(3, 47, 84, 0.25);
}

.menu-item.active::before {
  height: 24px;
}

/* Tooltip */
.menu-item::after {
  content: attr(data-tooltip);
  position: absolute;
  left: 72px;
  background: rgba(30, 41, 59, 0.95);
  color: white;
  padding: 8px 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transform: translateX(-8px);
  transition: all 0.3s ease;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
  z-index: 100;
}

.menu-item:hover::after {
  opacity: 1;
  transform: translateX(0);
}

.menu-divider {
  width: 32px;
  height: 1px;
  background: rgba(0, 0, 0, 0.08);
  margin: 8px 0;
}

.sidebar-bottom {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 16px;
}

/* MAIN CONTENT ━━━━━━━━━━━━━━━━━━━━━━━ */
.main-content {
  flex: 1;
  padding: 45px 60px;
  overflow-y: auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 35px;
}

.title {
  font-size: 32px;
  font-weight: 800;
  color: #032F54;
}

.subtitle {
  font-size: 15px;
  color: #64748b;
  margin-top: 4px;
}

/* STATS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 25px;
  margin-bottom: 45px;
}

.stat-box {
  background: white;
  border-radius: 20px;
  padding: 28px;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.06);
  transition: all 0.3s ease;
  border: 2px solid transparent;
}

.stat-box:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 35px rgba(0, 0, 0, 0.1);
  border-color: #032F54;
}

.stat-icon {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, rgba(3, 47, 84, 0.1), rgba(10, 80, 130, 0.1));
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  margin-bottom: 16px;
}

.stat-label {
  font-size: 14px;
  font-weight: 600;
  color: #64748b;
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 32px;
  font-weight: 800;
  color: #032F54;
}

/* FEATURE CARDS ━━━━━━━━━━━━━━━━━━━━━━━ */
.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #032F54;
  margin-bottom: 25px;
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 28px;
}

.card {
  background: white;
  border-radius: 20px;
  padding: 32px;
  text-decoration: none;
  color: #032F54;
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.06);
  transition: all 0.3s ease;
  border: 2px solid transparent;
  position: relative;
  overflow: hidden;
}

.card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #032F54, #0a5082);
  transform: scaleX(0);
  transition: transform 0.3s ease;
}

.card:hover::before {
  transform: scaleX(1);
}

.card:hover {
  transform: translateY(-6px);
  border-color: #032F54;
  box-shadow: 0 16px 40px rgba(3, 47, 84, 0.15);
}

.card-icon {
  font-size: 36px;
  margin-bottom: 16px;
  display: block;
}

.card-title {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 10px;
}

.card-description {
  color: #64748b;
  font-size: 14px;
  line-height: 1.6;
}

/* Featured Card */
.card.featured {
  background: linear-gradient(135deg, #032F54 0%, #0a5082 100%);
  color: white;
}

.card.featured .card-title {
  color: white;
}

.card.featured .card-description {
  color: rgba(255, 255, 255, 0.9);
}

.card.featured:hover {
  border-color: transparent;
  box-shadow: 0 20px 50px rgba(3, 47, 84, 0.3);
}

/* Scrollbar */
.main-content::-webkit-scrollbar {
  width: 8px;
}

.main-content::-webkit-scrollbar-track {
  background: transparent;
}

.main-content::-webkit-scrollbar-thumb {
  background: rgba(3, 47, 84, 0.2);
  border-radius: 10px;
}

.main-content::-webkit-scrollbar-thumb:hover {
  background: rgba(3, 47, 84, 0.3);
}

/* Responsive */
@media (max-width: 768px) {
  .sidebar {
    width: 70px;
    padding: 20px 0;
  }

  .main-content {
    padding: 30px 20px;
  }

  .stats {
    grid-template-columns: repeat(2, 1fr);
  }

  .card-grid {
    grid-template-columns: 1fr;
  }
}
  </style>
</head>

<body>

  <!-- Modern Sidebar -->
  <div class="sidebar">
    <div class="sidebar-logo">🏥</div>

    <div class="menu">
      <a href="/" class="menu-item active" data-tooltip="Dashboard">
        <span>🏠</span>
      </a>
      <a href="/customer/form" class="menu-item" data-tooltip="Tạo tài khoản">
        <span>👤</span>
      </a>
      <a href="/customer/list" class="menu-item" data-tooltip="Danh sách khách hàng">
        <span>📋</span>
      </a>
      <a href="/customer/list-sp" class="menu-item" data-tooltip="Lịch sử điểm">
        <span>📊</span>
      </a>
      <a href="/customer/revenue" class="menu-item" data-tooltip="Doanh thu bán hàng">
        <span>💰</span>
      </a>
    </div>

    <div class="sidebar-bottom">
      <div class="menu-divider"></div>
      <a href="#" class="menu-item" data-tooltip="Cài đặt">
        <span>⚙️</span>
      </a>
      <a href="#" class="menu-item" data-tooltip="Trợ giúp">
        <span>❓</span>
      </a>
    </div>
  </div>

  <!-- Main Content -->
  <div class="main-content">
    <div class="header">
      <div>
        <div class="title">Nhà thuốc Vĩnh Hằng</div>
        <div class="subtitle">Chào mừng trở lại "Hội người bệnh"!</div>
      </div>
    </div>


    <!-- Features -->
    <div class="section-title">Chức năng chính</div>
    <div class="card-grid">
      <a href="/customer/form" class="card">
        <span class="card-icon">➕</span>
        <div class="card-title">Tạo tài khoản</div>
        <div class="card-description">
          Đăng ký thông tin khách hàng mới nhanh chóng và dễ dàng.
        </div>
      </a>

      <a href="/customer/list" class="card">
        <span class="card-icon">📝</span>
        <div class="card-title">Danh sách khách hàng</div>
        <div class="card-description">
          Xem và quản lý tất cả thông tin khách hàng trong hệ thống.
        </div>
      </a>

      <a href="/customer/list-sp" class="card">
        <span class="card-icon">🎁</span>
        <div class="card-title">Lịch sử điểm tích lũy</div>
        <div class="card-description">
          Theo dõi điểm thưởng chi tiết của từng khách hàng.
        </div>
      </a>

      <a href="/customer/revenue" class="card featured">
        <span class="card-icon">📈</span>
        <div class="card-title">Doanh thu bán hàng</div>
        <div class="card-description">
          Xem báo cáo doanh thu thực tế và tiềm năng theo tháng/năm.
        </div>
      </a>

    
    </div>
  </div>

</body>
</html>
  `);
});


const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server chạy tại: http://localhost:${PORT}`);
});