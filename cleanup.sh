#!/bin/bash

docker kill varnish
docker rm varnish
docker kill magento
docker rm magento
docker kill rabbitmq
docker rm rabbitmq
docker kill redis
docker rm redis
docker kill mysql
docker rm mysql
docker kill elasticsearch
docker rm elasticsearch

docker volume rm mysql
docker volume rm elasticsearch
docker volume rm rabbitmq
docker volume rm magento