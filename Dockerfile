FROM kestra/kestra:v0.20.12

USER root
# Install required packages, download Oracle Instant Client, and unzip it
RUN  apt-get update && \
    apt-get install -y curl unzip && \
    rm -rf /var/lib/apt/lists/* && \
    curl -o /opt/oracle-instantclient.zip "https://download.oracle.com/otn_software/linux/instantclient/1926000/instantclient-basic-linux.x64-19.26.0.0.0dbru.zip" && \
    cd /opt && \
    unzip oracle-instantclient.zip
    
RUN apt-get update && \
    apt-get install -y libaio1 && \
    ldconfig
RUN apt-get update && \
    apt-get install  libaio-dev

ENV LD_LIBRARY_PATH=/opt/instantclient_19_26

RUN pip install --upgrade pip
RUN pip install oracledb==2.5.1
RUN pip install pandas==2.2.3
RUN pip install sqlalchemy==2.0.38
RUN pip install pymysql==1.1.1
RUN pip install pysolr==3.10.0
RUN pip install tqdm==4.67.1
RUN pip install cx_oracle==8.3.0
RUN pip install numpy==1.26.4
RUN pip install boto3==1.37.5

CMD ["server", "standalone"]
