const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const CustomerController = require('../controllers/customerController').CustomerController;
const containsController = require('../controllers/customerController').containsController;
const advancedController = new CustomerController();


// 3.1 - CRUD cơ bản (dùng customer-list.ejs với modal)
router.get('/list-all', customerController.getListAll); // Danh sách chính
router.get('/form', customerController.getForm);         // Redirect về list-all
router.post('/add', customerController.addCustomer);     // Thêm mới
router.post('/update', customerController.updateCustomer); // Cập nhật
router.post('/delete', customerController.deleteCustomer); // Xóa

// 3.2: Danh sách khách hàng
router.get('/list', customerController.getList_Right);
router.get('/list-one-on-one', customerController.getList_Right);


// 3.3 - Quản lý nâng cao (dùng list.ejs)
router.get('/list-sp', advancedController.getList.bind(advancedController));   
router.get('/loyal', advancedController.getLoyal.bind(advancedController)); 

router.get('/revenue', containsController.revenue);


module.exports = router;