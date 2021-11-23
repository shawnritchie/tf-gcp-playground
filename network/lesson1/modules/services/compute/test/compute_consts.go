package test

import "time"

const (
	vpcID					= "us_vpc_id"

	sshKeyBastionPublicIP   = "us_nat"
	sshKeyBastionPublicKey  = "BASTION_PUBLIC_KEY"
	sshKeyBastionPrivateKey = "BASTION_PRIVATE_KEY"
	extPublicSSHKeyLoc		= "./.ssh/gcp_instance.pub"

	osLoginBastionId		 = "us_computer_resource_id"
	osLoginBastionPublicIP	 = "us_nat"

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
