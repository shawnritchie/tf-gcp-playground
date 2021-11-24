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

func TestTerraformSSHKeyExample(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_sshkey_bootstrap", "true")
	//os.Setenv("SKIP_sshkey_deploy", "true")
	//os.Setenv("SKIP_sshkey_test_setup", "true")
	//os.Setenv("SKIP_sshkey_test_icmp", "true")
	//os.Setenv("SKIP_sshkey_test_ssh", "true")
	//os.Setenv("SKIP_sshkey_teardown", "true")

	testCtx := createTestContext(t, "../../", "compute/examples/ssh-key")
	cpExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "sshkey_bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, userEmail)
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		publicKey := readFile(t, extPublicSSHKeyLoc)
		assert.NotEmpty(t, publicKey)

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: cpExampleDir,

			Vars: map[string]interface{}{
				"ssh_key": map[string]interface{}{
					"ssh_user": sshUserName,
					"ssh_pub_key": publicKey,
				},
			},

			VarFiles: []string{"varfile.tfvars"},

			EnvVars: map[string]string{
				"GOOGLE_CLOUD_PROJECT": projectId,
			},
		})

		test_structure.SaveTerraformOptions(t, cpExampleDir, opts)
		testCtx.opt = opts
		testCtx.saveString(sshUsername, sshUserName)
	})

	defer test_structure.RunTestStage(t, "sshkey_teardown", func() {
		terraform.Destroy(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "sshkey_deploy", func() {
		terraform.InitAndApply(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "sshkey_test_setup", func() {

		testCtx.assertValidResourceId(vpcID)
		testCtx.assertValidResourceId(osLoginBastionId)

		testCtx.extractIP(sshKeyBastionPublicIP)

		testCtx.saveString(sshKeyBastionPublicKey, readFile(t, "./.ssh/gcp_instance.pub"))
		testCtx.saveString(sshKeyBastionPrivateKey, readFile(t,"./.ssh/gcp_instance"))
	})

	test_structure.RunTestStage(t, "sshkey_test_icmp", func() {
		host := testCtx.loadString(sshKeyBastionPublicIP)
		stats := pingHost(t, host)

		log.Printf("%d packets transmitted, %d packets received, %v%% packet loss\n",
			stats.PacketsSent, stats.PacketsRecv, stats.PacketLoss)
		assert.True(t, stats.PacketsRecv > 0, "at least single successfully ping")
	})

	test_structure.RunTestStage(t, "sshkey_test_ssh", func() {
		sshUserName := test_structure.LoadString(t, cpExampleDir, sshUsername)
		host := test_structure.LoadString(t, cpExampleDir, sshKeyBastionPublicIP)
		keyPair := getKeyPair(t, cpExampleDir)

		bastionHost := ssh.Host{
			Hostname:    host,
			SshKeyPair:  keyPair,
			SshUserName: sshUserName,
		}

		_, err := doWithRetryAndTimeoutE(t, "Attempting to SSH", SSHMaxRetries, SSHSleepBetweenRetries, SSHTimeout, func() (string, error) {
			testEchoOnComputeInstance(t, bastionHost)
			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}