package test

import "time"

const (
	SSH_USERNAME			 = "ssh_username"
	LOAD_BALANCER_IP		 = "loadbalancer_ip"
	SSH_HOST_IP              = "ssh_host_ip"
	PROJECT_ID				 = "project_id"

	userEmail				 = "shawn.ritchie@spinvadors.com"

	SSHMaxRetries 			 = 5
	SSHMaxRetriesExpectError = 5
	SSHSleepBetweenRetries   = 60 * time.Second
	SSHTimeout               = 15 * time.Second
	SSHEchoText              = "Hello World"

	pingMaxRetries			 = 3
	pingTimeout				 = 3 * time.Second
)