package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"regexp"
	"testing"
)

func TestInternalRegionalHTTPLoadBalancer(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	os.Setenv("SKIP_test_setup", "true")
	os.Setenv("SKIP_test_icmp", "true")
	os.Setenv("SKIP_test_load_balancer_from_ssh_host", "true")

	testCtx := createTestContext(t, "../../", "load-balancer/examples/internal/regional/https")
	vpcExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, userEmail)
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: vpcExampleDir,
		})

		test_structure.SaveTerraformOptions(t, vpcExampleDir, opts)
		test_structure.SaveString(t, vpcExampleDir, SSH_USERNAME, sshUserName)
		testCtx.opt = opts
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraform.InitAndApply(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "test_setup", func() {
		projectId := terraform.Output(testCtx.t, testCtx.opt, PROJECT_ID)
		region := terraform.Output(testCtx.t, testCtx.opt, "region")
		instanceGroupName := terraform.Output(testCtx.t, testCtx.opt, "instance_group_name")

		group := gcp.FetchRegionalInstanceGroup(t, projectId, region, instanceGroupName)
		instances := group.GetInstances(t,projectId)

		errMsg := "two instances should exist be contained in instance group"
		assert.NotEmpty(testCtx.t, instances, errMsg)
		assert.True(testCtx.t, len(instances) == 2, errMsg)

		sshHostIP := instances[0].GetPublicIp(t)
		assert.NotNil(testCtx.t, instances, errMsg)
		assert.NotEmpty(testCtx.t, instances, errMsg)
		testCtx.saveString(SSH_HOST_IP, sshHostIP)

		loadBalancerIP := terraform.Output(testCtx.t, testCtx.opt, LOAD_BALANCER_IP)
		testCtx.saveString(LOAD_BALANCER_IP, loadBalancerIP)
	})

	test_structure.RunTestStage(t, "test_icmp", func() {
		host := testCtx.loadString(SSH_HOST_IP)
		stats := pingHost(t, host)

		log.Printf("%d packets transmitted, %d packets received, %v%% packet loss\n",
			stats.PacketsSent, stats.PacketsRecv, stats.PacketLoss)
		assert.True(t, stats.PacketsRecv > 0, "at least single successfully ping")
	})

	test_structure.RunTestStage(t, "test_load_balancer_from_ssh_host", func() {
		projectId := terraform.Output(testCtx.t, testCtx.opt, PROJECT_ID)
		sshUserName := testCtx.loadString(SSH_USERNAME)
		host := testCtx.loadString(SSH_HOST_IP)
		loadBalancerIP := testCtx.loadString(LOAD_BALANCER_IP)

		keyPair := ssh.GenerateRSAKeyPair(t, 2048)
		key := keyPair.PublicKey

		defer gcp.DeleteSSHKey(t, userEmail, key)
		ImportSSHKeyE(t, userEmail, projectId, key)

		bastionHost := ssh.Host{
			Hostname:    host,
			SshKeyPair:  keyPair,
			SshUserName: sshUserName,
		}

		_, err := doWithRetryAndTimeoutE(t, "Attempting to SSH", SSHMaxRetries, SSHSleepBetweenRetries, SSHTimeout, func() (string, error) {
			testEchoOnComputeInstance(t, bastionHost)

			output, err := ssh.CheckSshCommandE(t, bastionHost, fmt.Sprintf("curl -I %s", loadBalancerIP))
			if err != nil {
				t.Fatal(err)
			}

			re := regexp.MustCompile("HTTP.* 200 OK")
			assert.Regexp(t, re, output, fmt.Sprintf("Curl request to host: %v fialed.\nOutput: %v", host, output))

			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}