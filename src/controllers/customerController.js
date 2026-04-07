const { poolPromise } = require('../config/db');
const sql = require('mssql');

/**
 * Hiển thị form thêm hoặc sửa khách hàng
 * ⚠️ REDIRECT sang customer-list với modal hoặc trang riêng
 */
exports.getForm = async (req, res) => {
  const { id } = req.query;
  
  // Nếu không có ID -> redirect về list để thêm mới
  if (!id) {
    return res.redirect('/customer/list-all?action=add');
  }
  
  // Nếu có ID -> redirect về list để sửa
  res.redirect(`/customer/list-all?action=edit&id=${id}`);
};

/**
 * Xử lý THÊM khách hàng mới (POST)
 */
exports.addCustomer = async (req, res) => {
  try {
    const pool = await poolPromise;
    const { FullName, Birthdate, Email, Phone, Gender } = req.body;

    // ✅ KIỂM TRA số điện thoại trùng
    if (Phone && Phone.trim()) {
      const checkPhone = await pool.request()
        .input('Phone', sql.VarChar, Phone.trim())
        .query('SELECT CustomerID FROM dbo.Customer WHERE Phone = @Phone');
      
      if (checkPhone.recordset.length > 0) {
        throw new Error('Số điện thoại đã tồn tại trong hệ thống!');
      }
    }

    // ✅ KIỂM TRA ngày sinh
    if (Birthdate) {
      const birthDate = new Date(Birthdate);
      const today = new Date();
      
      // Kiểm tra ngày sinh > hiện tại
      if (birthDate > today) {
        throw new Error('Ngày tháng năm sinh không được vượt quá thời điểm hiện tại!');
      }
      
      // Tính tuổi
      let age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();
      const dayDiff = today.getDate() - birthDate.getDate();
      
      if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
        age--;
      }
      
      // Kiểm tra tuổi tối thiểu 16
      if (age < 16) {
        throw new Error('Khách hàng phải đủ 16 tuổi trở lên!');
      }
    }

    await pool.request()
      .input('FullName', sql.NVarChar, FullName || null)
      .input('Birthdate', sql.Date, Birthdate || null)
      .input('Email', sql.VarChar, Email || null)
      .input('Phone', sql.VarChar, Phone || null)
      .input('Gender', sql.NVarChar, Gender || null)
      .query(`
        INSERT INTO dbo.Customer (FullName, Birthdate, Email, Phone, Gender)
        VALUES (@FullName, @Birthdate, @Email, @Phone, @Gender)
      `);

    res.redirect('/customer/list-all?success=Thêm khách hàng thành công!');
    
  } catch (err) {
    res.redirect('/customer/list-all?error=' + encodeURIComponent(err.message));
  }
};

/**
 * Xử lý CẬP NHẬT khách hàng
 */
exports.updateCustomer = async (req, res) => {
  try {
    const pool = await poolPromise;
    const { CustomerID, FullName, Birthdate, Email, Phone, Gender } = req.body;

    // ✅ KIỂM TRA số điện thoại trùng (ngoại trừ chính khách hàng đang sửa)
    if (Phone && Phone.trim()) {
      const checkPhone = await pool.request()
        .input('Phone', sql.VarChar, Phone.trim())
        .input('CustomerID', sql.Int, CustomerID)
        .query('SELECT CustomerID FROM dbo.Customer WHERE Phone = @Phone AND CustomerID != @CustomerID');
      
      if (checkPhone.recordset.length > 0) {
        const msg = 'Số điện thoại đã tồn tại trong hệ thống!';
        if (req.get('X-Requested-With') === 'XMLHttpRequest') {
          return res.json({ success: false, message: msg });
        }
        throw new Error(msg);
      }
    }

    // ✅ KIỂM TRA ngày sinh
    if (Birthdate) {
      const birthDate = new Date(Birthdate);
      const today = new Date();
      
      // Kiểm tra ngày sinh > hiện tại
      if (birthDate > today) {
        throw new Error('Ngày tháng năm sinh không được lớn hơn ngày hiện tại!');
      }
      
      // Tính tuổi
      let age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();
      const dayDiff = today.getDate() - birthDate.getDate();
      
      if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
        age--;
      }
      
      // Kiểm tra tuổi tối thiểu 16
      if (age < 16) {
        throw new Error('Khách hàng phải đủ 16 tuổi trở lên!');
      }
    }

    const result = await pool.request()
      .input('CustomerID', sql.Int, CustomerID)
      .input('FullName', sql.NVarChar, FullName || null)
      .input('Birthdate', sql.Date, Birthdate || null)
      .input('Email', sql.VarChar, Email || null)
      .input('Phone', sql.VarChar, Phone || null)
      .input('Gender', sql.NVarChar, Gender || null)
      .query(`
        UPDATE dbo.Customer
        SET FullName = @FullName,
            Birthdate = @Birthdate,
            Email = @Email,
            Phone = @Phone,
            Gender = @Gender
        WHERE CustomerID = @CustomerID
      `);

    if (result.rowsAffected[0] === 0) {
      throw new Error('Không tìm thấy khách hàng để cập nhật');
    }

    // Ở cuối khi cập nhật thành công
    if (req.get('X-Requested-With') === 'XMLHttpRequest') {
      return res.json({ success: true, message: 'Cập nhật thành công!' });
    }

    // Lấy Referer để redirect về đúng trang
    const referer = req.get('Referer') || '/customer/list-all';
    const redirectUrl = referer.includes('list-one-on-one') 
      ? '/customer/list-one-on-one' 
      : '/customer/list-all';
    
    res.redirect(`${redirectUrl}?success=Cập nhật thành công!`);
    
  } catch (err) {
    console.error('Error in updateCustomer:', err);
    
    // Lấy Referer để redirect về đúng trang khi lỗi
    const referer = req.get('Referer') || '/customer/list-all';
    const redirectUrl = referer.includes('list-one-on-one') 
      ? '/customer/list-one-on-one' 
      : '/customer/list-all';
    
    res.redirect(`${redirectUrl}?error=${encodeURIComponent(err.message)}`);
  }
};

/**
 * Xử lý XÓA khách hàng (AJAX)
 */
exports.deleteCustomer = async (req, res) => {
  try {
    const pool = await poolPromise;
    
    const result = await pool.request()
      .input('CustomerID', req.body.CustomerID)
      .query(`
        DELETE FROM dbo.Customer
        WHERE CustomerID = @CustomerID
      `);

    if (result.rowsAffected[0] === 0) {
      throw new Error('Không tìm thấy khách hàng để xóa');
    }

    res.json({ success: true, message: 'Xóa thành công!' });
    
  } catch (err) {
    res.json({ success: false, message: err.message });
  }
};

/**
 * Hiển thị DANH SÁCH khách hàng (customer-list.ejs)
 */
exports.getListAll = async (req, res) => {
  try {
    const pool = await poolPromise;
    const result = await pool.request()
      .query('SELECT * FROM dbo.Customer ORDER BY CustomerID DESC');

    res.render('customer-list', {
      customers: result.recordset,
      success: req.query.success || null,
      error: req.query.error || null,
      title: 'Danh sách khách hàng'
    });
  } catch (err) {
    res.status(500).send('Lỗi kết nối CSDL: ' + err.message);
  }
};

/**
 * Danh sách khách hàng với tìm kiếm và sắp xếp
 */
exports.getList_Right = async (req, res) => {
  let sort = req.query.sort || "CustomerID";
  let order = req.query.order || "ASC";

  // Chỉ cho phép sort theo ID
  const allowedSort = ["CustomerID"];
  if (!allowedSort.includes(sort)) sort = "CustomerID";

  if (order !== "ASC" && order !== "DESC") order = "ASC";

  try {
    const pool = await poolPromise;
    const search = req.query.search?.trim() || "";

    let query = `SELECT * FROM dbo.Customer`;

    if (search) {
      query += `
        WHERE 
          Phone LIKE '%' + @Search + '%'
          OR FullName LIKE '%' + @Search + '%'
          OR Email LIKE '%' + @Search + '%'
      `;
    }

    query += ` ORDER BY ${sort} ${order}`;

    const result = await pool.request()
      .input("Search", sql.NVarChar, search)
      .query(query);

    res.render("list-one-on-one", {
      customers: result.recordset,
      search,
      sort,
      order,
      success: req.query.success || null,
      error: req.query.error || null,
      title: "Danh sách khách hàng",
    });

  } catch (err) {
    res.status(500).send("Lỗi kết nối CSDL: " + err.message);
  }
};

/**
 * CLASS Controller cho các chức năng nâng cao
 */
class CustomerController {
  // 3.3.1. Danh sách khách hàng + Điểm tích lũy tìm kiếm theo SĐT
  async getList(req, res) {
    const phone = req.query.phone?.trim() || '';
    
    try {
      const pool = await poolPromise;
      let result;

      if (phone) {
        // Nếu nhập phone, gọi stored procedure
        result = await pool.request()
          .input('Phone', sql.VarChar, phone)
          .execute('GetCustomerAndPoints_ByPhone');
      } else {
        // Nếu không nhập phone, lấy tất cả khách hàng
        result = await pool.request()
          .query(`
            SELECT 
              C.CustomerID,
              C.FullName,
              C.Email,
              C.Phone,
              ISNULL(SUM(MP.Points), 0) AS CurrentPoints
            FROM dbo.Customer C
            LEFT JOIN dbo.MembershipPoint MP ON C.CustomerID = MP.CustomerID
            GROUP BY C.CustomerID, C.FullName, C.Email, C.Phone
          `);
      }
      
      res.render('list', {
        customers: result.recordset,
        phoneSearch: phone,
        loyalCustomers: [],
        showLoyalTab: false,
        filter: null,
        error: null,
        success: req.query.success || null
      });
    } catch (err) {
      console.error('Error in getList:', err);
      res.render('list', { 
        error: err.message, 
        customers: [], 
        loyalCustomers: [], 
        showLoyalTab: false,
        phoneSearch: phone,
        filter: null,
        success: null
      });
    }
  }

  // 3.3.2. Khách hàng trung thành theo Điểm tích lũy + Số lần mua
  async getLoyal(req, res) {
    const { start = '2025-01-01', end = '2025-12-31', minValue = 500, minFreq = 3 } = req.query;
    
    try {
      const pool = await poolPromise;
      const result = await pool.request()
        .input('StartDate', sql.Date, start)
        .input('EndDate', sql.Date, end)
        .input('MinTotalAmount', sql.Int, parseInt(minValue))
        .input('MinFrequency', sql.Int, parseInt(minFreq))
        .execute('GetLoyalCustomers_ByAmountAndFrequency');

      res.render('list', {
        customers: [],
        loyalCustomers: result.recordset,
        showLoyalTab: true,
        filter: { start, end, minValue, minFreq },
        phoneSearch: '',
        error: null,
        success: null
      });
    } catch (err) {
      console.error('Error in getLoyal:', err);
      res.render('list', { 
        error: err.message, 
        loyalCustomers: [], 
        showLoyalTab: true,
        customers: [],
        filter: { start, end, minValue, minFreq },
        phoneSearch: '',
        success: null
      });
    }
  }
}

/**
 * containsController - Doanh thu thực và tiềm năng
 */
class containsController {
  async revenue(req, res) {
    try {
      let { month = new Date().getMonth() + 1, year = new Date().getFullYear() } = req.query;
      month = parseInt(month);
      year = parseInt(year);

      const pool = await poolPromise;
      const result = await pool.request()
        .input('Month', sql.Int, month)
        .input('Year', sql.Int, year)
        .query(`
          SELECT * FROM dbo.Fn_Revenue_Real_vs_Potential_Month(@Month, @Year)
        `);

      if (!result.recordset || result.recordset.length === 0) {
        return res.render('revenue', { 
          month, 
          year, 
          result: null, 
          error: 'Không có dữ liệu' 
        });
      }

      const row = result.recordset[0];
      
      // Lấy tên cột động từ kết quả
      const columns = Object.keys(row);
      const firstCol = row[columns[0]];
      const secondCol = row[columns[1]];
      const thirdCol = row[columns[2]];
      
      // Nếu tháng/năm sai → hàm trả về -1,-1,-1
      if (firstCol === -1 && secondCol === -1 && thirdCol === -1) {
        return res.render('revenue', { 
          month, 
          year, 
          result: null, 
          error: 'Tháng hoặc năm không hợp lệ!' 
        });
      }

      res.render('revenue', {
        month,
        year,
        result: { 
          actual: parseFloat(firstCol), 
          potential: parseFloat(secondCol), 
          lost: parseFloat(thirdCol) 
        },
        error: null
      });
    } catch (err) {
      console.error('Error in revenue:', err);
      res.render('revenue', { 
        month: req.query.month || new Date().getMonth() + 1, 
        year: req.query.year || new Date().getFullYear(), 
        result: null, 
        error: err.message 
      });
    }
  }
}

// ✅ EXPORT
module.exports = exports;
module.exports.CustomerController = CustomerController;
module.exports.containsController = new containsController();