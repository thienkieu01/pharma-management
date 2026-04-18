# 💊 Online Pharmacy Management System

🚀 A **database-centric system** that simulates a real-world pharmacy platform, focusing on **data integrity, transactional workflows, and automated business logic** using SQL Server.

---

## 🧩 Overview

This project models an **online pharmacy (B2C)** where:

* Customers browse and purchase products
* Pharmacists manage orders
* The system enforces business rules automatically at the database level

Unlike typical CRUD applications, this project emphasizes:

* Strong **relational database design**
* **Triggers & Stored Procedures** for business logic
* Real-world **transaction flow simulation**

---

## ⚡ Tech Stack

| Layer        | Technology                          |
| ------------ | ----------------------------------- |
| Database     | SQL Server                          |
| Language     | T-SQL                               |
| Tools        | SQL Server Management Studio (SSMS) |
| Architecture | Relational Database (EER → SQL)     |

---

## 🏗️ Database Architecture

```text
Database (SQL Server)
├── Tables
├── Constraints
├── Stored Procedures
└── Triggers
```

---

## 🧠 Database Design

### 🔹 Core Tables

* `Product` (base entity)
* `Medicine`, `Supplement`, `MedicalDevice`, `BeautyProduct` (inheritance)
* `Category`
* `Customer`, `CustomerAddress`
* `Order`, `Contains` (order details)
* `Payment`, `Delivery`
* `MembershipPoint`
* `Review`
* `Pharmacist`
* `Consult`

---

### 🔹 Design Highlights

#### ✔ Inheritance (IS-A)

```text
Product
├── Medicine
├── Supplement
├── MedicalDevice
└── BeautyProduct
```

#### ✔ E-commerce Order System

```text
Customer → Order → Contains → Product
                     ↓
              Payment + Delivery
```

#### ✔ Loyalty System

```text
Customer → MembershipPoint
```

---

## 🔒 Data Integrity

Enforced directly at database level:

* Unique phone number for each customer
* Non-negative price and stock
* Order status constraint:

  * `Processing`, `Shipped`, `Completed`, `Canceled`
* Rating range: 1 → 5

---

## 🔥 Core Features

### 👤 Customer Management

* Insert / Update / Delete using stored procedures
* Validation:

  * Age ≥ 16
  * Unique phone number
  * Prevent deletion if related orders exist

---

### 🧾 Order Processing

* Multi-step order lifecycle
* Automatic total calculation
* Status transition control

---

### 💰 Payment & Delivery

* Linked 1:1 with order
* Automated status updates

---

### 🎯 Loyalty System

* Points = `FLOOR(TotalPay / 1000)`
* Automatically updated via triggers
* Ensures data consistency

---

## ⚙️ Advanced Database Logic

### 🔹 Triggers

* Auto update payment status after delivery
* Auto complete order when conditions are met
* Automatically calculate:

  * Subtotal
  * TotalAmount
* Reset order value when canceled
* Prevent invalid data updates

---

### 🔹 Stored Procedures

* `sp_InsertCustomer`
* `sp_UpdateCustomer`
* `sp_DeleteCustomer`

Features:

* Input validation
* Error handling (`TRY...CATCH`)
* Business rule enforcement

---

## 🔄 Transaction Flow

```text
1. Customer places order
2. Insert Order + Contains
3. Trigger → calculate totals
4. Payment created
5. Delivery updated
6. Triggers:
   → Payment → Paid
   → Order → Completed
   → Add loyalty points
```

---

## 📊 Analytical Capabilities

* Track customer loyalty points history
* Identify loyal customers based on:

  * Total spending
  * Purchase frequency
* Uses SQL aggregation & window functions

---

## 🛠 Database Setup

Run the following scripts in order:

```bash
schema.sql
procedures.sql
triggers.sql
seed.sql (optional)
```

This will fully recreate the database with all business logic.

---

## 📈 Key Achievements

* Designed a **complex relational database with inheritance**
* Implemented **business logic at database layer**
* Built a **transactional system similar to e-commerce**
* Applied **triggers for automation & consistency**
* Ensured **data integrity with constraints**

---

## 🚀 Future Improvements

* Build REST API (Node.js / Django)
* Add authentication system (JWT)
* Develop frontend (React)
* Deploy using Docker / Cloud

---

## 👨‍💻 Authors

* Phan Cao Thiên Kiều
* Huỳnh Lê Phương Linh
* Dương Thị Bảo Trân

---

## 📄 License

This project is for educational purposes.
