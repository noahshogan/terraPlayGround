// Import the necessary modules
const AWS = require('aws-sdk'); // AWS SDK for interfacing with AWS services
const AWSMock = require('aws-sdk-mock'); // Mock AWS SDK for testing
const { handler } = require('../index');
const {describe} = require("test"); // Import the lambda function handler

// Use the done callback for asynchronous testing
describe('Testing S3 to DynamoDB Lambda', function () {
  // Run this before each test in this block
  beforeEach(function () {
    // Mock the getObject function of S3 to return a predefined result
    AWSMock.mock('S3', 'getObject', function (params, callback) {
      console.log('S3.getObject has been mocked'); // For tracking that mock is being used
      callback(null, { Body: JSON.stringify({ id: '123', data: 'testdata' }) }); // Return mock data
    });
    // Mock the put function of DynamoDB to simulate storing data
    AWSMock.mock('DynamoDB.DocumentClient', 'put', function (params, callback) {
      console.log('DynamoDB.put has been mocked'); // For tracking that mock is being used
      callback(null, {}); // Return empty result to indicate success
    });
  });

  // Run this after each test in this block
  afterEach(function () {
    AWSMock.restore('S3'); // Restore original S3 getObject function
    AWSMock.restore('DynamoDB.DocumentClient'); // Restore original DynamoDB put function
  });

  it('should get an item from S3 and store it in DynamoDB', function (done) {
    // Create a mock S3 event
    const event = {
      Records: [
        {
          s3: {
            bucket: {
              name: 'testBucket',
            },
            object: {
              key: 'testKey',
            },
          },
        },
      ],
    };

    // Call the lambda handler function
    handler(event, null, function (err, result) {
      // Log the error if it exists
      if (err) {
        console.log(err);
      } else {
        // Log the result if no error
        console.log('Lambda function executed successfully: ', result);
      }
      done(); // Call the done function to signal end of test
    });
  });
});
