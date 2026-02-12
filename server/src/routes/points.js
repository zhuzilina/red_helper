const express = require('express');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 获取积分分布
router.get('/distribution', (req, res) => {
  db.all(
    "SELECT * FROM points_distribution ORDER BY points DESC",
    (err, rows) => {
      if (err) {
        logger.error('查询积分分布失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取积分分布失败'
        });
      }

      res.status(200).json({
        success: true,
        data: rows
      });
    }
  );
});

// 获取用户总积分
router.get('/total', (req, res) => {
  const userId = req.user.id;

  db.get(
    "SELECT points FROM users WHERE id = ?",
    [userId],
    (err, result) => {
      if (err) {
        logger.error('查询用户积分失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取积分失败'
        });
      }

      if (!result) {
        return res.status(404).json({
          success: false,
          message: '用户不存在'
        });
      }

      res.status(200).json({
        success: true,
        data: result.points
      });
    }
  );
});

// 获取每日任务
router.get('/DailyTask', (req, res) => {
  db.all(
    "SELECT * FROM daily_tasks ORDER BY id ASC",
    (err, rows) => {
      if (err) {
        logger.error('查询每日任务失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取每日任务失败'
        });
      }

      res.status(200).json({
        success: true,
        data: rows
      });
    }
  );
});

// 签到功能
router.get('/signin', (req, res) => {
  const userId = req.user.id;
  const today = new Date().toISOString().split('T')[0];

  // 检查今天是否已经签到
  db.get(
    "SELECT id FROM sign_in_records WHERE user_id = ? AND sign_in_date = ?",
    [userId, today],
    (err, existingRecord) => {
      if (err) {
        logger.error('查询签到记录失败:', err);
        return res.status(500).json({
          success: false,
          message: '签到失败'
        });
      }

      if (existingRecord) {
        return res.status(400).json({
          success: false,
          message: '今天已经签到过了'
        });
      }

      // 执行签到
      const pointsEarned = 10;
      
      db.run(
        "INSERT INTO sign_in_records (user_id, sign_in_date, points_earned) VALUES (?, ?, ?)",
        [userId, today, pointsEarned],
        function(err) {
          if (err) {
            logger.error('插入签到记录失败:', err);
            return res.status(500).json({
              success: false,
              message: '签到失败'
            });
          }

          // 更新用户积分
          db.run(
            "UPDATE users SET points = points + ? WHERE id = ?",
            [pointsEarned, userId],
            function(err) {
              if (err) {
                logger.error('更新用户积分失败:', err);
                return res.status(500).json({
                  success: false,
                  message: '签到失败'
                });
              }

              logger.info(`用户签到成功: ${userId}, 获得积分: ${pointsEarned}`);

              res.status(200).json({
                success: true,
                message: '签到成功',
                data: {
                  points: pointsEarned
                }
              });
            }
          );
        }
      );
    }
  );
});

module.exports = router;




