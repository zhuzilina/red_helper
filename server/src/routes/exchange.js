const express = require('express');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

const router = express.Router();

// 兑换商品
router.post('/', (req, res) => {
  const userId = req.user.id;
  const { productId } = req.body;

  if (!productId) {
    return res.status(400).json({
      success: false,
      message: '商品ID不能为空'
    });
  }

  // 查询商品信息
  db.get(
    "SELECT * FROM products WHERE id = ?",
    [productId],
    (err, product) => {
      if (err) {
        logger.error('查询商品失败:', err);
        return res.status(500).json({
          success: false,
          message: '兑换失败'
        });
      }

      if (!product) {
        return res.status(404).json({
          success: false,
          message: '商品不存在'
        });
      }

      if (product.stock <= 0) {
        return res.status(400).json({
          success: false,
          message: '商品库存不足'
        });
      }

      // 查询用户积分
      db.get(
        "SELECT points FROM users WHERE id = ?",
        [userId],
        (err, user) => {
          if (err) {
            logger.error('查询用户积分失败:', err);
            return res.status(500).json({
              success: false,
              message: '兑换失败'
            });
          }

          if (!user) {
            return res.status(404).json({
              success: false,
              message: '用户不存在'
            });
          }

          if (user.points < product.points_required) {
            return res.status(400).json({
              success: false,
              message: '积分不足'
            });
          }

          // 执行兑换
          const newPoints = user.points - product.points_required;

          db.run(
            "UPDATE users SET points = ? WHERE id = ?",
            [newPoints, userId],
            function(err) {
              if (err) {
                logger.error('更新用户积分失败:', err);
                return res.status(500).json({
                  success: false,
                  message: '兑换失败'
                });
              }

              // 更新商品库存
              db.run(
                "UPDATE products SET stock = stock - 1 WHERE id = ?",
                [productId],
                function(err) {
                  if (err) {
                    logger.error('更新商品库存失败:', err);
                    return res.status(500).json({
                      success: false,
                      message: '兑换失败'
                    });
                  }

                  // 记录兑换记录
                  db.run(
                    "INSERT INTO exchange_records (user_id, product_id, points_spent) VALUES (?, ?, ?)",
                    [userId, productId, product.points_required],
                    function(err) {
                      if (err) {
                        logger.error('记录兑换记录失败:', err);
                        // 这里不返回错误，因为兑换已经成功
                      }

                      logger.info(`用户兑换成功: ${userId}, 商品: ${product.name}, 消耗积分: ${product.points_required}`);

                      res.status(200).json({
                        success: true,
                        message: '兑换成功',
                        data: {
                          newPoints,
                          product: {
                            id: product.id,
                            name: product.name,
                            pointsSpent: product.points_required
                          }
                        }
                      });
                    }
                  );
                }
              );
            }
          );
        }
      );
    }
  );
});

// 获取兑换记录
router.get('/records', (req, res) => {
  const userId = req.user.id;

  db.all(
    `SELECT er.*, p.name as product_name, p.image as product_image 
     FROM exchange_records er 
     JOIN products p ON er.product_id = p.id 
     WHERE er.user_id = ? 
     ORDER BY er.created_at DESC`,
    [userId],
    (err, rows) => {
      if (err) {
        logger.error('查询兑换记录失败:', err);
        return res.status(500).json({
          success: false,
          message: '获取兑换记录失败'
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




