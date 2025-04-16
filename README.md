### This process creates a CloudFormation stack that includes a DynamoDB table, an IAM role, a Lambda function, and an API Gateway. It then adds a test item to table, deploys the API, and tests the API endpoint with a GET request, verifying correct response.

You will need:

- An AWS account. (If AWS acct is less than 12 months old and you're not close to limits for these services, this should all be within free tier)

STEPS

1. Clone this repo or download the .zip and extract.
2. In your AWS Account, create a new bucket and name it whatever you like (default settings fine).
3. From the repo you just cloned/downloaded, upload folder 'stack-creation-files' directly into your bucket. (Folder includes the CloudFormation YAML file for the stack, the .zip file with small Node.js server app for the Lambda, an env file for defining config variables, a bash script to create the stack, add DynamoDB item, deploy API, and then test it), and another bash script to delete the stack
4. In file config-vars.env, change REGION and BUCKET_NAME to match the bucket you just created.
5. Save changes.
6. In your AWS console, go into the CloudShell environment, and run the following three comands, substituting your own bucket name:

    - ```aws s3 sync "s3://your-bucket-name/stack-creation-files/" "/tmp/stack-creation-files"```  
    - ```cd ./tmp/stack-creation-files```  
    - ```bash create-stack-and-test-api-endpoint.sh```

    *Output should show several check marks, and end with JSON content from API response: [{"projectId":"save-the-day","strategy":"speed","userId":"superman"}]

7. If not using long-term, delete stack with:  
    - ```bash delete-stack.sh```

<br>

#### Summary of the CloudFormation template (dynamo-lambda-api-cf-stack.yaml). It will:

- Check if stack with name 'projects-app-cf-stack' already exists; if so, it will delete it.
- Create a CloudFormation stack which includes an IAM execution role, Lambda function, DynamoDB table (with partition key userId and sort key projectId), and an API Gateway which invokes the Lambda function with a GET request.
- Create a sample Dynamo table item with userId: superman, projectId: save-the-day, and strategy: speed
- Deploy API to 'prod' in the new API Gateway
- Get invoke URL (callable endpoint will be at path: /projects)
- curl w/ userId=superman
- Verify that response matches expected JSON
