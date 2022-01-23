package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"net/http"
	"testing"
)

func TestExternalRegionalHTTPLoadBalancer(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_test_setup", "true")
	//os.Setenv("SKIP_test_icmp", "true")
	//os.Setenv("SKIP_test_load_balancer_via_public_get_request", "true")

	testCtx := createTestContext(t, "../../", "load-balancer/examples/external/regional/https")
	vpcExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "bootstrap", func() {
		opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: vpcExampleDir,
		})

		test_structure.SaveTerraformOptions(t, vpcExampleDir, opts)
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

	test_structure.RunTestStage(t, "test_load_balancer_via_public_get_request", func() {
		loadBalancerIP := testCtx.loadString(LOAD_BALANCER_IP)


		_, err := doWithRetryAndTimeoutE(t, "Attempting to Curl", SSHMaxRetries, SSHSleepBetweenRetries, SSHTimeout, func() (string, error) {

			resp, err := http.Get(fmt.Sprintf("http://%s:80/", loadBalancerIP))
			if err != nil {
				log.Fatalln(err)
			}

			if resp.StatusCode != 200 {
				log.Fatalf("Expected error code is 200 received %v", resp.StatusCode)
			}

			return "", nil
		})

		if err != nil {
			t.Fatalf("Expected success but saw: %s", err)
		}
	})
}