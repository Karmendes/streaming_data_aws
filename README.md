# Specifications

This is a personal project based on my experience using these services at work. It is not intended to be too comprehensive either in data traffic size
and custom settings. The proposal is to be as simple as possible and detailing the services and points for improvement.

# Architecture

![](images/Arquitetura.png)

We will be using **terraform** for managing the services. Here is a brief description of your duties

### data simulator 

This service is built in python 3.9.1 and aims to simulate fake data from an IoT sensor.
The details of the contract would be:

- Temperature
- cpu level
- Ram level
- HD level
- Timestamp: Time the data was created
- Timestamp_sent: Time the data was sent (yyyy-mm-dd HH)

From the creation of the data, it is sent to **Kinesis** via Boto3

### Kinesis Firehose
This service aims to receive fake data from the application in python, transform them into parquet files and insert them into S3 in a partitioned way.

This service was chosen for the following reasons:

- Low cost of data traffic: 0.029 USD per Gb in the first 500GB
- Possibility to transform the die into parquet with simple configuration
- Possibility to insert data in a partitioned way in S3 in a simple way
- Does not need to be managed

### S3
This service allows data to be stored cheaply and also has integrations with some AWS analytics services like Athena and Redshift (Spectrum).
We create a bucket on S3 to receive the kinesis data. This bucket would be partitioned by the timestamp_sent coming from kinesis.
Here's how it would look on S3

### Glue
It is intended to catalog the database and the table that we will create from the S3 data. It will also run a crawler for reading via Athena.

### Athena
End user contact service. From this, we can make queries to look for some information or metrics.

# Project structure


# how to replicate

1. Clone the repository on your machine

```
git clone https://github.com/Karmendes/streaming_data_aws
```
2. If you don't have it yet, download terraform and set the environment variable path to the terraform bin

3. Make sure your computer has the AWS CLI configured.

4. Create a virtual environment in python, go to the **streaming_data_aws/src/fake_iot_data** directory and run the following command

```
pip -r requiremnts.txt
```
5. Go to the streaming_data_aws/src/infra directory and run the following command

```
terraform apply
```

Wait until everything is created.

6. In the root of the directory, start the fakes data generator.

```
python streaming_data_aws/src/fake_iot_dat/sender.py
```

7. Log into your AWS account, log into the glue service and run the crawler

8. Go to the athena service, select the database and the table that refer to the data and that's it. You will already be able to write queries directly in S3.


# What could be done further?


1. **Permissions**:
For the sake of simplicity, I created roles with very open policies. Ideally, you only allow permissions for the resources being used.

2. **Additional Transformation**:
We could put some ETL process to treat the data in another way. Splitting the bucket into raw, processed and trusted. In this way, the data could arrive
raw, be transformed into parquet in a glue job, transform the dates from string to date and make them available in the trusted layer.

3. **Real-Time Processing**:
Imagine that we need to give a real-time alert about some anomaly in the data. We could put another kinesis service in front of firehose, the data stream,
which works similar to kafka. Thus, another application could fetch this data and, according to its business rule, detect an anomaly.

4. **Gateway to Edge**:
Imagine the fake data script turned into a real application on an IoT device. In order not to put credentials on the edge, for security reasons, we could
put a gateway in front of the AWS services so that it would redirect to Kinesis.
