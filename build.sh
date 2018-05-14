#!/bin/sh

cd $(dirname $0)
sudo docker build -t rozyhead/apache-php5.1 .
