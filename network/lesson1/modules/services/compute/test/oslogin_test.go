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

func TestTerraformOsLoginExample(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_oslogin_bootstrap", "true")
	//os.Setenv("SKIP_oslogin_deploy", "true")
	//os.Setenv("SKIP_oslogin_teardown", "true")
	//os.Setenv("SKIP_oslogin_test_setup", "true")
	//os.Setenv("SKIP_oslogin_test_icmp", "true")
	//os.Setenv("SKIP_oslogin_test_ssh", "true")

	testCtx := createTestContext(t, "../../", "compute/examples/oslogin")
	cpExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "oslogin_bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, userEmail)
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: cpExampleDir,

			VarFiles: []string{"varfile.tfvars"},

			EnvVars: map[string]string{
				"GOOGLE_CLOUD_PROJECT": projectId,
			},
		})

		test_structure.SaveTerraformOptions(t, cpExampleDir, opts)
		testCtx.opt = opts
		testCtx.saveString(sshUsername, sshUserName)
	})

	defer test_structure.RunTestStage(t, "oslogin_teardown", func() {
		terraform.Destroy(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "oslogin_deploy", func() {
		terraform.InitAndApply(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "oslogin_test_setup", func() {

		testCtx.assertValidResourceId(vpcID)
		testCtx.assertValidResourceId(osLoginBastionId)

		testCtx.extractIP(osLoginBastionPublicIP)
	})

	test_structure.RunTestStage(t, "oslogin_test_icmp", func() {
		host := testCtx.loadString(osLoginBastionPublicIP)
		stats := pingHost(t, host)

		log.Printf("%d packets transmitted, %d packets received, %v%% packet loss\n",
			stats.PacketsSent, stats.PacketsRecv, stats.PacketLoss)
		assert.True(t, stats.PacketsRecv > 0, "at least single successfully ping")
	})

	test_structure.RunTestStage(t, "oslogin_test_ssh", func() {
		keyPair := ssh.GenerateRSAKeyPair(t, 2048)
		sshUserName := test_structure.LoadString(t, cpExampleDir, sshUsername)
		host := test_structure.LoadString(t, cpExampleDir, osLoginBastionPublicIP)
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
			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}
