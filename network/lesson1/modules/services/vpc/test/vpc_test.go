package test

import (
	"fmt"
	"github.com/go-ping/ping"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	t "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"log"
	"regexp"
	"testing"
	"time"
)

var (
	SSHMaxRetries = 20
	// we don't want to retry for too long, but we should do it at least a few times to make sure the instance is up
	SSHMaxRetriesExpectError = 3
	SSHSleepBetweenRetries   = 5 * time.Second
	SSHTimeout               = 15 * time.Second
	SSHEchoText              = "Hello World"
)

func TestTerraformVPCResourceExample(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_test_setup", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_test_icmp", "true")

	vpcExampleDir := test_structure.CopyTerraformFolderToTemp(t, "../../", "vpc/examples")

	test_structure.RunTestStage(t, "bootstrap", func() {

		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// website::tag::1::Set the path to the Terraform code that will be tested.
			// The path to where our Terraform code is located
			TerraformDir: vpcExampleDir,

			// Variables to pass to our Terraform code using -var-file options
			VarFiles: []string{"varfile.tfvars"},
		})

		test_structure.SaveTerraformOptions(t, vpcExampleDir, opts)
		test_structure.SaveString(t, vpcExampleDir, "LIBA", "fniek")
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, vpcExampleDir)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, vpcExampleDir)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "test_setup", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, vpcExampleDir)

		assertValidResourceId(t, terraformOptions, "us_a_vpc_id")
		assertValidResourceId(t, terraformOptions, "us_b_vpc_id")
		assertValidResourceId(t, terraformOptions, "us_a_computer_resource_id")
		assertValidResourceId(t, terraformOptions, "us_b_computer_resource_id")
	})

	test_structure.RunTestStage(t, "test_icmp", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, vpcExampleDir)
		publicIP := terraform.Output(t, terraformOptions, "us_b_nat")
		re := regexp.MustCompile("\\[(.*)\\]")
		match := re.FindStringSubmatch(publicIP)

		fmt.Println(match[1])
		log.Printf("IP: %#v", match[1])

		pinger, err := ping.NewPinger(match[1])
		if err != nil {
			t.Error(err)
		}

		pinger.Count = 3
		err = pinger.Run()
		if err != nil {
			t.Error(err)
		}

		stats := pinger.Statistics()

		log.Printf("%d packets transmitted, %d packets received, %v%% packet loss\n",
			stats.PacketsSent, stats.PacketsRecv, stats.PacketLoss)
		assert.True(t, stats.PacketsRecv > 0, "at least single successfully ping")
	})
}

func assertValidResourceId(t t.TestingT, options *terraform.Options, key string) {
	extractedResource := terraform.Output(t, options, key)

	assert.NotNil(t, extractedResource, fmt.Sprintf("%s should not be null", key))
	assert.NotEmpty(t, extractedResource, fmt.Sprintf("%s should not empty", key))
}

func doWithRetryAndTimeoutE(t *testing.T, description string, maxRetries int, sshSleepBetweenRetries time.Duration, timeoutPerRetry time.Duration, action func() (string, error)) (string, error) {
	return retry.DoWithRetryE(t, description, maxRetries, sshSleepBetweenRetries, func() (string, error) {
		return retry.DoWithTimeoutE(t, description, timeoutPerRetry, action)
	})
}