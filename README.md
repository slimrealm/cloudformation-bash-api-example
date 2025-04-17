### Example of using CloudFormation to create a stack that includes a DynamoDB table, an IAM role, a Lambda function, and an API Gateway.  A bash script calls the CloudFormation YAML, adds a test item to DynamoDB table, deploys the API, and tests the API endpoint with a GET request, verifying correct response.

<br>

Please feel free to run it yourself!
You will need:

- An AWS account (As of April 2025, if the account is less than 12 months old and not close to limits for these services, it should all be within free tier.)
- Basic familiarity with AWS console (or knowledge of how to perform steps with AWS CLI).

<br>

### Steps

---

1. Clone this repo - or download the .zip and extract.
2. In your AWS Account, create a new S3 bucket and name it whatever you like (default settings are fine).
3. In the local repo you just cloned/downloaded, open file ```stack-creation-files/config-vars.env```, and update the values of BUCKET_NAME and AWS_REGION, to match the bucket you just created.
4. Save changes.
5.  In your new S3 bucket, 'Upload Folder' -- upload just the ```stack-creation-files``` folder*.
6. In your AWS console, go into the CloudShell environment, and run the following three comands, substituting your own bucket name:

    - ```aws s3 sync "s3://your-bucket-name/stack-creation-files/" "/tmp/stack-creation-files" --exact-timestamp```  
    - ```cd /tmp/stack-creation-files```  
    - ```bash create-stack-and-test-api-endpoint.sh```

    Output should indicate several successful operations, and end with JSON content from API response: [{"projectId":"save-the-day","strategy":"speed","userId":"superman"}]

7. If not using this infrastructure long-term, you can delete stack from the CloudShell command line, within the same directory:  
    - ```bash delete-stack.sh```

*The ```stack-creation-files``` folder includes the CloudFormation YAML file for the stack, the .zip file for the Lambda containing a small Node.js API handler, an env file for defining config variables, a bash script to create and test the infrastructure stack, and a second script to delete the stack.

<br>

### Summary of the main script (```create-stack-and-test-api-endpoint.sh```). It will:
---

- Check if stack with name 'projects-app-cf-stack' already exists; if so, it will delete it.
- Create a CloudFormation stack using ```dynamo-lambda-api-cf-stack.yaml```, which includes an IAM execution role, Lambda function, DynamoDB table (with partition key ```userId``` and sort key ```projectId```), and an API Gateway which invokes the Lambda function with a GET request.
- Create a sample DynamoDB table item with userId: superman, projectId: save-the-day, and strategy: speed
- Deploy API to 'prod' stage in the new API Gateway
- Get invoke URL (the callable endpoint will be at path ```/projects```)
- ```curl``` this URL -- GET request w/ query param: userId=superman
- Verify that response matches expected JSON
