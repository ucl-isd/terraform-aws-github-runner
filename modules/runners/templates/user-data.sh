#!/bin/bash -e

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# AWS suggest to create a log for debug purpose based on https://aws.amazon.com/premiumsupport/knowledge-center/ec2-linux-log-user-data/
# As side effect all command, set +x disable debugging explicitly.
#
# An alternative for masking tokens could be: exec > >(sed 's/--token\ [^ ]* /--token\ *** /g' > /var/log/user-data.log) 2>&1

set +x

%{ if enable_debug_logging }
set -x
%{ endif }


echo "export sonar_token=cfc682a63b68d4" > /etc/profile.d/env_vars.sh
echo "sonar_token1=123456787654321" >> /etc/profile.d/env_vars.sh
chmod +x /etc/profile.d/my_env_vars.sh


${pre_install}

yum update -y

# Install docker
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user

yum install -y amazon-cloudwatch-agent curl jq git

user_name=ec2-user

${install_runner}

${post_install}

${start_runner}
