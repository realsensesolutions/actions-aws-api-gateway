const request = require('supertest');

// Import the actual app to test
const express = require('express');
const cors = require('cors');

// Create a test version of the app without serverless wrapper and server start
const createApp = () => {
  const app = express();
  app.use(express.json());
  app.use(cors());

  // Add the GET / route that we implemented in app.js
  app.get('/', (req, res) => {
    res.status(200).json({ message: "hello from API Gateway" });
  });

  app.post('/plus', async (httpReq, httpResp) => {
    const resp = await require('./plus').handler(httpReq);
    httpResp
      .status(resp.status)
      .json(resp.body);
  });

  return app;
};

describe('GET /', () => {
  test('should return hello from API Gateway message', async () => {
    const app = createApp();
    const response = await request(app)
      .get('/')
      .expect(200);
    
    expect(response.body).toEqual({
      message: "hello from API Gateway"
    });
  });
}); 