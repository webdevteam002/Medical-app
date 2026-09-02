module.exports = {
  apps: [
    {
      name: 'medstudy-api',
      script: 'dist/main.js',
      cwd: '/home/ubuntu/medstudy/backend',
      instances: 1,
      autorestart: true,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
    },
  ],
};
