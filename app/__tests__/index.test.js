// Import the necessary modules
const AWSMock = require('aws-sdk-mock'); // Mock AWS SDK for testing
const { handler } = require('../index');

describe('Testing S3 to DynamoDB Lambda', function () {
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

    afterEach(function () {
        AWSMock.restore('S3'); // Restore the original S3 getObject function
        AWSMock.restore('DynamoDB.DocumentClient'); // Restore the original DynamoDB put function
    });

    it('should get an item from S3 and store it in DynamoDB', async function () {
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
        const result = await handler(event);

        // Log the result
        console.log('Lambda function executed successfully: ', result);
    });
});
