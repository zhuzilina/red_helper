const express = require('express');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 获取轮播书籍
router.get('/get', (req, res) => {
  db.all(
    "SELECT * FROM books WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 5",
    (err, rows) => {
      if (err) {
        logger.error('查询轮播书籍失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取轮播书籍失败'
        });
      }

      res.status(200).json({
        success: true,
        data: rows
      });
    }
  );
});

// 获取书籍列表
router.get('/list', (req, res) => {
  db.all(
    "SELECT * FROM books ORDER BY created_at DESC",
    (err, rows) => {
      if (err) {
        logger.error('查询书籍列表失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取书籍列表失败'
        });
      }

      res.status(200).json({
        success: true,
        data: rows
      });
    }
  );
});

module.exports = router;




