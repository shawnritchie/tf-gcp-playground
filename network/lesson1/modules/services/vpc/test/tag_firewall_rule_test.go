package test

import (
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"testing"
)

func TestTagFireWallVPCResourceExample(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_test_setup", "true")
	//os.Setenv("SKIP_test_icmp", "true")
	//os.Setenv("SKIP_test_private_vpc", "true")

	testCtx := createTestContext(t, "../../", "vpc/examples/tags")
	vpcExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, userEmail)
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: vpcExampleDir,

			VarFiles: []string{"varfile.tfvars"},

			EnvVars: map[string]string{
				"GOOGLE_CLOUD_PROJECT": projectId,
			},
		})

		test_structure.SaveTerraformOptions(t, vpcExampleDir, opts)
		test_structure.SaveString(t, vpcExampleDir, sshUsername, sshUserName)
		testCtx.opt = opts
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraform.InitAndApply(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "test_setup", func() {
		testCtx.assertValidResourceId(usVPC1)
		testCtx.assertValidResourceId(usVPC2)
		testCtx.assertValidResourceId(usPrivateInstanceId)
		testCtx.assertValidResourceId(osLoginBastionId)

		publicIp := testCtx.extractIP(osLoginBastionPublicIP)
		testCtx.saveString(osLoginBastionPublicIP, publicIp)
	})

	test_structure.RunTestStage(t, "test_icmp", func() {
		host := testCtx.loadString(osLoginBastionPublicIP)
		stats := pingHost(t, host)

		log.Printf("%d packets transmitted, %d packets received, %v%% packet loss\n",
			stats.PacketsSent, stats.PacketsRecv, stats.PacketLoss)
		assert.True(t, stats.PacketsRecv > 0, "at least single successfully ping")
	})

	test_structure.RunTestStage(t, "test_private_vpc", func() {
		sshUserName := testCtx.loadString(sshUsername)
		host := testCtx.loadString(osLoginBastionPublicIP)

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

			privateIP := testCtx.extractIP(usPrivateInstanceIP)
			testPingComputeInstanceViaBastionHost(t, bastionHost, privateIP)

			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}