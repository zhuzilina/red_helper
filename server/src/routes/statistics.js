const express = require('express');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 获取积分排行
router.get('/pointsranking', (req, res) => {
  db.all(
    "SELECT * FROM friend_ranking ORDER BY rank ASC",
    (err, rows) => {
      if (err) {
        logger.error('查询积分排行失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取积分排行失败'
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




