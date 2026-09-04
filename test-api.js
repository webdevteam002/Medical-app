const http = require('http');

const loginData = JSON.stringify({
  email: 'student@test.com',
  password: 'Student123!',
  deviceId: 'test-device-123',
  deviceName: 'Test Device'
});

const req = http.request({
  hostname: 'localhost',
  port: 3000,
  path: '/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const response = JSON.parse(data);
    console.log('Login Response:', response);
    
    if (response.accessToken) {
      // Fetch subscriptions
      const subReq = http.request({
        hostname: 'localhost',
        port: 3000,
        path: '/v1/subscriptions/me',
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${response.accessToken}`,
          'x-device-id': 'test-device-123'
        }
      }, (subRes) => {
        let subData = '';
        subRes.on('data', chunk => subData += chunk);
        subRes.on('end', () => {
          console.log('\nSubscriptions Response:', JSON.parse(subData));
        });
      });
      subReq.end();
    }
  });
});

req.on('error', error => console.error(error));
req.write(loginData);
req.end();
