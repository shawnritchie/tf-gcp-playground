package test

import "time"

const (
	usVPC1					 = "us_a_vpc_id"
	usVPC2					 = "us_b_vpc_id"

	usPrivateInstanceId		 = "us_a_computer_resource_id"
	usPrivateInstanceIP		 = "us_a_private_ips"

	osLoginBastionId  		 = "us_b_computer_resource_id"
	osLoginBastionPublicIP	 = "us_b_nat"

	sshUsername				 = "SSH_USERNAME"
	projectId				 = "tf-state-329314"
	userEmail				 = "sracggcp@gmail.com"

	SSHMaxRetries 			 = 2
	SSHMaxRetriesExpectError = 3
	SSHSleepBetweenRetries   = 5 * time.Second
	SSHTimeout               = 15 * time.Second
	SSHEchoText              = "Hello World"

	pingMaxRetries			 = 3
	pingTimeout				 = 3 * time.Second
)