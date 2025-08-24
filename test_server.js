const axios = require('axios');

const BASE_URL = 'http://localhost:8080';

// 测试数据
const testUser = {
  username: 'testuser',
  password: 'TestPass123'
};

async function testServer() {
  console.log('🧪 开始测试临时认证服务器...\n');

  try {
    // 1. 测试健康检查
    console.log('1. 测试健康检查...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ 健康检查通过:', healthResponse.data.message);
    console.log('');

    // 2. 测试用户注册
    console.log('2. 测试用户注册...');
    const registerResponse = await axios.post(`${BASE_URL}/user/register`, testUser);
    console.log('✅ 注册成功:', registerResponse.data.message);
    console.log('   用户ID:', registerResponse.data.data.userId);
    console.log('');

    // 3. 测试用户登录
    console.log('3. 测试用户登录...');
    const loginResponse = await axios.post(`${BASE_URL}/user/login`, testUser);
    console.log('✅ 登录成功:', loginResponse.data.message);
    const token = loginResponse.data.data.token;
    console.log('   获取到令牌:', token.substring(0, 20) + '...');
    console.log('');

    // 4. 测试令牌验证
    console.log('4. 测试令牌验证...');
    const verifyResponse = await axios.get(`${BASE_URL}/user/verify`, {
      headers: { token }
    });
    console.log('✅ 令牌验证成功:', verifyResponse.data.message);
    console.log('');

    // 5. 测试获取用户信息
    console.log('5. 测试获取用户信息...');
    const profileResponse = await axios.get(`${BASE_URL}/user/profile`, {
      headers: { token }
    });
    console.log('✅ 获取用户信息成功');
    console.log('   用户名:', profileResponse.data.data.username);
    console.log('   用户ID:', profileResponse.data.data.userId);
    console.log('');

    // 6. 测试重复注册（应该失败）
    console.log('6. 测试重复注册（应该失败）...');
    try {
      await axios.post(`${BASE_URL}/user/register`, testUser);
      console.log('❌ 重复注册应该失败但没有失败');
    } catch (error) {
      if (error.response && error.response.status === 400) {
        console.log('✅ 重复注册正确失败:', error.response.data.message);
      } else {
        console.log('❌ 重复注册测试异常:', error.message);
      }
    }
    console.log('');

    // 7. 测试错误密码登录（应该失败）
    console.log('7. 测试错误密码登录（应该失败）...');
    try {
      await axios.post(`${BASE_URL}/user/login`, {
        username: testUser.username,
        password: 'wrongpassword'
      });
      console.log('❌ 错误密码登录应该失败但没有失败');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ 错误密码登录正确失败:', error.response.data.message);
      } else {
        console.log('❌ 错误密码登录测试异常:', error.message);
      }
    }
    console.log('');

    console.log('🎉 所有测试通过！服务器运行正常。');
    console.log('\n📝 测试账号信息:');
    console.log(`   用户名: ${testUser.username}`);
    console.log(`   密码: ${testUser.password}`);
    console.log('\n🔗 服务器地址: http://localhost:8080');

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 请确保服务器正在运行: npm start');
    }
  }
}

// 运行测试
testServer();
