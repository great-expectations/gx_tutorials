# Great Expectations with AWS Glue Data Catalog Tutorial

The purpose of this example is to show how [Great Expectations](https://greatexpectations.io) can be used together with [AWS Glue Data Catalog](https://docs.aws.amazon.com/glue/latest/dg/catalog-and-crawler.html) to validate your data lake through tables organized into databases. This repository contains a notebook and terraform code to setup the required resources in your AWS account to use the new Great Expectations Glue Catalog Connector.

## Project Structure
```
gx_glue_catalog_tutorial
├── infra                                           # Terraform code
│   └── ...
├── notebooks
│   └── GE-Demo-GlueCatalog-QuickStart.ipynb        # Quickstart notebook
└── README.md
```

## Prerequisites

To setup the environment required for this tutorial, make sure you have the following:
1. An AWS account to deploy the required AWS resources.
2. A machine with the following tools installed and configured:
    1. [AWS Command Line Interface (AWS CLI)](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html).
    2. [Terraform](https://www.terraform.io/).
    3. [Git](https://git-scm.com/downloads).

## Solution Deployment

To deploy the required resources into your AWS account, follow these steps:
1. In the command line, use the AWS CLI to setup the credentials to login into your AWS Account. Another option is to use environment variables, refer to the following as an example:
    ```sh
    export AWS_ACCESS_KEY_ID=***********
    export AWS_SECRET_ACCESS_KEY=***********
    export AWS_DEFAULT_REGION=us-east-1
    ```

2. Validate that you are authenticated by running the following code:
    ```sh
    aws sts get-caller-identity
    ```
    This command will output the UserId and Account you are authenticated.

3. Once you validated your credentials, run the following to deploy the solution into your account:
    ```sh
    cd gx_glue_catalog_tutorial/infra
    terraform init & terraform apply -auto-approve
    ```
4. Log in to the [AWS Console](https://aws.amazon.com/console/) using the same account used for the solution deployment, navigate to S3 and check the buckets. You shall have a bucket named **great-expectations-glue-demo-<AWS_ACCOUNT_ID>-<AWS_REGION>**.

5. In the [AWS Console](https://aws.amazon.com/console/), navigate to Glue and, in Data Catalog, open databases. You shall have a database named **db_ge_with_glue_demo**. 

6. Open the database and check its tables, you shall have a table named **tb_nyc_trip_data**. Open the table and check its partitions, you shall have three partitions, named: 2022-01, 2022-02, and 2022-03.

7. In Glue console, open Jobs in AWS Glue Studio, select Jupyter Notebook and *Upload and edit an existing notebook*. Select Choose file, upload the [**GE-Demo-GlueCatalog-QuickStart.ipynb**](notebooks/GE-Demo-GlueCatalog-QuickStart.ipynb) that is in the notebook’s directory of the code repository and create the job.

8. In the Notebook setup, enter a name of your choice and, in the IAM Role, select the role **GE-Glue-Demo-Role**. This role has been deployed for you as part of the solution deployment. Select Spark as the Kernel and start the notebook.

Once you have completed all these steps, you shall have your environment ready to start working with Great Expectations and AWS Glue Data Catalog. Follow the instructions in the Glue Notebook you have created.