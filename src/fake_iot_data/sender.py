import random
from datetime import datetime
from time import sleep

class Generator:
    def __inti__(self):
        self.data = None

    def generate_data(self):
        self.data = {
                    'temperature': random.randint(0,100),
                    'cpu':random.random(),
                    'ram':random.random(),
                    'hd':random.random(),
                    'timestamp': str(datetime.now()),
                    'id_device':random.randint(0,10)
                }
    
    def printer_in_screem(self):
        print(self.data)

if __name__ == "__main__":
    iot_data = Generator()
    while True:
        iot_data.generate_data()
        iot_data.printer_in_screem()
        sleep(2)





