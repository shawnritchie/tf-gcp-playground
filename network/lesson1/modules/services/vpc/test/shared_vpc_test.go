package test

import (
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"testing"
)

func TestTerraformSharedVPCResourceExample(t *testing.T) {
	t.Parallel()

	os.Setenv("SKIP_bootstrap", "true")
	os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	os.Setenv("SKIP_test_setup", "true")
	os.Setenv("SKIP_test_shared_vpc", "true")

	testCtx := createTestContext(t, "../../", "vpc/examples/shared-vpc")
	vpcExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, userEmail)
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: vpcExampleDir,

			VarFiles: []string{"varfile.tfvars"},
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
		testCtx.assertValidResourceId("shared_vpc_id")
		testCtx.assertValidResourceId("left_compute_resource_id")
		testCtx.assertValidResourceId("right_compute_resource_id")
		testCtx.assertValidResourceId("right_compute_resource_id")
	})

	test_structure.RunTestStage(t, "test_shared_vpc", func() {
		sshUserName := testCtx.loadString(sshUsername)
		host := testCtx.extractIP("right_compute_resource_nat")
		projectId := testCtx.extractOutput("right_host_project")

		keyPair := ssh.GenerateRSAKeyPair(t, 2048)
		key := keyPair.PublicKey

		defer gcp.DeleteSSHKey(t, userEmail, key)
		if err := ImportSSHKeyE(t, userEmail, projectId, key); err != nil {
			log.Fatalf("Error: %v", err)
		}

		bastionHost := ssh.Host{
			Hostname:    host,
			SshKeyPair:  keyPair,
			SshUserName: sshUserName,
		}

		_, err := doWithRetryAndTimeoutE(t, "Attempting to SSH", SSHMaxRetries, SSHSleepBetweenRetries, SSHTimeout, func() (string, error) {
			testEchoOnComputeInstance(t, bastionHost)

			privateIP := testCtx.extractIP("left_compute_resource_private_ips")
			testPingComputeInstanceViaBastionHost(t, bastionHost, privateIP)

			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}