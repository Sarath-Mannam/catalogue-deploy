# APP_VERSION=$1
# echo "app version: $APP_VERSION"
# yum install python3.11-devel python3.11-pip -y
# pip3.11 install ansible botocore boto3
# cd /tmp
# ansible-pull -U https://github.com/Sarath-Mannam/-ansible-roboshop-roles-tf.git -e component=catalogue -e app_version=$APP_VERSION main.yaml

#!/bin/bash
APP_VERSION=$1
echo "app version: $APP_VERSION"

# Install Python 3.6 and dependencies
yum install python36 python36-devel python36-pip -y

# Install necessary Python packages using pip3.6
pip3.6 install ansible botocore boto3

# Change to the temporary directory
cd /tmp

# Run ansible-pull to fetch the roles and execute the playbook
ansible-pull -U https://github.com/Sarath-Mannam/-ansible-roboshop-roles-tf.git \
  -e component=catalogue \
  -e app_version=$APP_VERSION \
  main.yaml
