const bcrypt = require('bcryptjs');

// 测试密码哈希
async function testPassword() {
  const password = 'TestPass123';
  const hashedPassword = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';
  
  console.log('测试密码:', password);
  console.log('存储的哈希:', hashedPassword);
  
  // 验证密码
  const isValid = await bcrypt.compare(password, hashedPassword);
  console.log('密码验证结果:', isValid);
  
  // 生成新的哈希
  const newHash = await bcrypt.hash(password, 10);
  console.log('新生成的哈希:', newHash);
  
  // 验证新哈希
  const isValidNew = await bcrypt.compare(password, newHash);
  console.log('新哈希验证结果:', isValidNew);
}

testPassword();






