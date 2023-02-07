import random
from datetime import datetime,timedelta
from time import sleep
import boto3
import json

class Generator:
    def __inti__(self):
        self.data = None

    def generate_data(self):
        self.data = {
                    'temperature': random.randint(0,100),
                    'cpu':random.random(),
                    'ram':random.random(),
                    'hd':random.random(),
                    'timestamp': str(datetime.now() - timedelta(minutes = random.randint(0,180))),
                    'timestamp_sent': str(datetime.now().strftime("%Y-%m-%d %H")),
                    'id_device':random.randint(0,10)
                }
    
    def printer_in_screem(self):
        print(self.data)

class SenderToKinesis(Generator):
    def __init__(self,service = 'firehose'):
        self.service = service
        self.client = boto3.client(self.service)
    
    def send_record_to_kinesis(self,name_stream):
        self.generate_data()
        self.client.put_record(
                DeliveryStreamName=name_stream,
                Record={
                    'Data': json.dumps(self.data).encode('utf-8')
                    }
        )

if __name__ == "__main__":
    iot_data = SenderToKinesis()
    while True:
        iot_data.send_record_to_kinesis('stream_fake_iot')
        iot_data.printer_in_screem()
        sleep(1)





