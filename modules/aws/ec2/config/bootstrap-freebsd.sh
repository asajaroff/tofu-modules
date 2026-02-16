#!/bin/sh
# Install SSM agent from FreeBSD ports (community package, not officially supported by AWS)
# https://www.freebsdsoftware.org/sysutils/amazon-ssm-agent.html

sudo pkg install -y amazon-ssm-agent
sudo sysrc amazon_ssm_agent_enable="YES"
sudo service amazon-ssm-agent start
