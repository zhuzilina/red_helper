const express = require('express');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 获取用户信息
router.get('/profile', (req, res) => {
  const userId = req.user.id;

  db.get(
    "SELECT id, username, nickname, email, avatar, points, created_at FROM users WHERE id = ?",
    [userId],
    (err, user) => {
      if (err) {
        logger.error('获取用户信息失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: '用户不存在'
        });
      }

      res.status(200).json({
        success: true,
        data: user
      });
    }
  );
});

// 更新用户信息
router.put('/profile', (req, res) => {
  const userId = req.user.id;
  const { nickname, email, avatar } = req.body;

  const updates = [];
  const values = [];

  if (nickname !== undefined) {
    updates.push('nickname = ?');
    values.push(nickname);
  }

  if (email !== undefined) {
    updates.push('email = ?');
    values.push(email);
  }

  if (avatar !== undefined) {
    updates.push('avatar = ?');
    values.push(avatar);
  }

  if (updates.length === 0) {
    return res.status(400).json({
      success: false,
      message: '没有提供要更新的字段'
    });
  }

  updates.push('updated_at = CURRENT_TIMESTAMP');
  values.push(userId);

  const sql = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;

  db.run(sql, values, function(err) {
    if (err) {
      logger.error('更新用户信息失败:', err);
      return res.status(500).json({
        success: false,
        message: '服务器内部错误'
      });
    }

    if (this.changes === 0) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }

    logger.info(`用户信息更新成功: ${userId}`);

    res.status(200).json({
      success: true,
      message: '用户信息更新成功'
    });
  });
});

// 获取用户积分
router.get('/points', (req, res) => {
  const userId = req.user.id;

  db.get(
    "SELECT points FROM users WHERE id = ?",
    [userId],
    (err, result) => {
      if (err) {
        logger.error('获取用户积分失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
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
        data: {
          points: result.points
        }
      });
    }
  );
});

module.exports = router;




