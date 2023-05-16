// Import AWS SDK to interact with AWS services
const AWS = require('aws-sdk');
AWS.config.update({region: 'us-east-1'});
// Create S3 service object to interact with S3
let s3 = null;

// Create DynamoDB document client to interact with DynamoDB
let dynamodb = null;

// This is the main Lambda function handler
exports.handler = async (event) => {
    s3 = new AWS.S3();
    dynamodb = new AWS.DynamoDB.DocumentClient();
    // Extract the bucket name and object key from the event that triggered the Lambda
    // The event is assumed to be an S3 Object Created event
    let bucket = event.Records[0].s3.bucket.name;
    let key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

    // Setup parameters for S3 getObject operation
    let getObjectParams = {
        Bucket: bucket,
        Key: key
    };

    // Retrieve object from S3 using the S3 getObject operation
    let s3Data = await s3.getObject(getObjectParams).promise();

    // Convert the S3 object data from a Buffer to a string and parse it as JSON
    let objectData = s3Data.Body.toString('utf-8');
    let jsonData = JSON.parse(objectData);

    // Setup parameters for DynamoDB put operation
    let putParams = {
        TableName: 's3_to_dynamodb',  // DynamoDB table name
        Item: {
            'id': jsonData.id,  // 'id' value from the JSON object
            'timestamp': new Date().getTime(),  // Current timestamp
            'data': jsonData.data  // 'data' value from the JSON object
        }
    };

    // Store data in DynamoDB using the put operation
    await dynamodb.put(putParams).promise();

    // Log the received event and parsed data to CloudWatch Logs
    console.log('Received event:', JSON.stringify(event, null, 2));
    console.log('Received data:', JSON.stringify(jsonData, null, 2));
};


