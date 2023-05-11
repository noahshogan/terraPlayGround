const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    let bucket = event.Records[0].s3.bucket.name;
    let key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

    let getObjectParams = {
        Bucket: bucket,
        Key: key
    };

    let s3Data = await s3.getObject(getObjectParams).promise();
    let objectData = s3Data.Body.toString('utf-8'); 
    let jsonData = JSON.parse(objectData);
    let putParams = {
        TableName: 's3_to_dynamodb',
        Item: {
            'id': jsonData.id,
            'timestamp': new Date().getTime(),
            'data': jsonData.data
        }
    };

    await dynamodb.put(putParams).promise();

    console.log('Received event:', JSON.stringify(event, null, 2));
    console.log('Received data:', JSON.stringify(jsonData, null, 2));
};


