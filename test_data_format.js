const axios = require('axios');

const BASE_URL = 'http://localhost:8080';

// 测试数据
const testUser = {
  username: 'testuser',
  password: 'TestPass123'
};

let authToken = '';

async function testDataFormat() {
  console.log('🧪 测试服务器数据格式...\n');

  try {
    // 1. 登录获取token
    console.log('1. 登录获取token...');
    const loginResponse = await axios.post(`${BASE_URL}/user/login`, testUser);
    authToken = loginResponse.data.data.token;
    console.log('✅ 登录成功，获取到token');

    // 2. 测试积分排行数据格式
    console.log('\n2. 测试积分排行数据格式...');
    const rankingResponse = await axios.get(`${BASE_URL}/statistics/pointsranking`, {
      headers: { token: authToken }
    });
    console.log('📊 积分排行原始数据:');
    console.log(JSON.stringify(rankingResponse.data.data, null, 2));

    // 3. 测试积分分布数据格式
    console.log('\n3. 测试积分分布数据格式...');
    const distributionResponse = await axios.get(`${BASE_URL}/points/distribution`, {
      headers: { token: authToken }
    });
    console.log('📊 积分分布原始数据:');
    console.log(JSON.stringify(distributionResponse.data.data, null, 2));

    // 4. 测试书籍数据格式
    console.log('\n4. 测试书籍数据格式...');
    const booksResponse = await axios.get(`${BASE_URL}/carouse/list`, {
      headers: { token: authToken }
    });
    console.log('📚 书籍原始数据:');
    console.log(JSON.stringify(booksResponse.data.data, null, 2));

    // 5. 测试每日任务数据格式
    console.log('\n5. 测试每日任务数据格式...');
    const tasksResponse = await axios.get(`${BASE_URL}/points/DailyTask`, {
      headers: { token: authToken }
    });
    console.log('📋 每日任务原始数据:');
    console.log(JSON.stringify(tasksResponse.data.data, null, 2));

    console.log('\n🎉 数据格式测试完成！');

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.response) {
      console.error('   状态码:', error.response.status);
      console.error('   错误信息:', error.response.data);
    }
  }
}

// 运行测试
testDataFormat();




