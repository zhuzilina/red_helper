const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 生成JWT令牌
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// 用户注册
router.post('/register', [
  body('username')
    .isLength({ min: 3, max: 20 })
    .withMessage('用户名长度必须在3-20个字符之间')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('用户名只能包含字母、数字和下划线'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('密码至少需要6个字符')
    .matches(/^(?=.*[a-zA-Z])(?=.*\d)/)
    .withMessage('密码必须包含字母和数字'),
  body('nickname')
    .optional()
    .isLength({ max: 50 })
    .withMessage('昵称不能超过50个字符')
], async (req, res) => {
  try {
    // 验证输入
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: '输入验证失败',
        errors: errors.array()
      });
    }

    const { username, password, nickname } = req.body;

    // 检查用户名是否已存在
    db.get("SELECT id FROM users WHERE username = ?", [username], async (err, existingUser) => {
      if (err) {
        logger.error('查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: '用户名已存在'
        });
      }

      // 加密密码
      const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // 创建用户
      db.run(
        "INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)",
        [username, hashedPassword, nickname || username],
        function(err) {
          if (err) {
            logger.error('创建用户失败:', err);
            return res.status(500).json({
              success: false,
              message: '服务器内部错误'
            });
          }

          // 生成令牌
          const token = generateToken(this.lastID);

          logger.info(`新用户注册成功: ${username}`);

          res.status(201).json({
            success: true,
            message: '注册成功',
            data: {
              userId: this.lastID,
              username,
              nickname: nickname || username,
              token
            }
          });
        }
      );
    });

  } catch (error) {
    logger.error('注册过程中发生错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 用户登录
router.post('/login', [
  body('username')
    .notEmpty()
    .withMessage('用户名不能为空'),
  body('password')
    .notEmpty()
    .withMessage('密码不能为空')
], async (req, res) => {
  try {
    // 验证输入
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: '输入验证失败',
        errors: errors.array()
      });
    }

    const { username, password } = req.body;

    // 查找用户
    db.get(
      "SELECT id, username, password, nickname, points FROM users WHERE username = ?",
      [username],
      async (err, user) => {
        if (err) {
          logger.error('查询用户失败:', err);
          return res.status(500).json({
            success: false,
            message: '服务器内部错误'
          });
        }

        if (!user) {
          return res.status(401).json({
            success: false,
            message: '用户名或密码错误'
          });
        }

        // 验证密码
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
          return res.status(401).json({
            success: false,
            message: '用户名或密码错误'
          });
        }

        // 生成令牌
        const token = generateToken(user.id);

        // 更新最后登录时间
        db.run(
          "UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = ?",
          [user.id]
        );

        logger.info(`用户登录成功: ${username}`);

        res.status(200).json({
          success: true,
          message: '登录成功',
          data: {
            userId: user.id,
            username: user.username,
            nickname: user.nickname,
            points: user.points,
            token
          }
        });
      }
    );

  } catch (error) {
    logger.error('登录过程中发生错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 验证令牌
router.get('/verify', (req, res) => {
  try {
    const token = req.header('token') || req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: '没有提供令牌'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 验证用户是否存在
    db.get("SELECT id, username, nickname FROM users WHERE id = ?", [decoded.userId], (err, user) => {
      if (err) {
        logger.error('验证令牌时查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (!user) {
        return res.status(401).json({
          success: false,
          message: '用户不存在'
        });
      }

      res.status(200).json({
        success: true,
        message: '令牌有效',
        data: {
          userId: user.id,
          username: user.username,
          nickname: user.nickname
        }
      });
    });

  } catch (error) {
    logger.error('令牌验证失败:', error);
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: '令牌已过期'
      });
    }

    return res.status(401).json({
      success: false,
      message: '无效的令牌'
    });
  }
});

module.exports = router;




