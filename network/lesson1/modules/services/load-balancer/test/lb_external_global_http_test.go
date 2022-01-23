package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"net/http"
	"os"
	"testing"
)

func TestExternalGlobalHTTPLoadBalancer(t *testing.T) {
	t.Parallel()

	os.Setenv("SKIP_bootstrap", "true")
	os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	os.Setenv("SKIP_test_setup", "true")
	os.Setenv("SKIP_test_load_balancer_via_public_get_request", "true")

	testCtx := createTestContext(t, "../../", "load-balancer/examples/external/global/https")
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
		errMsg := "Load Balance IP must be non nil and valid"
		loadBalancerIP := terraform.Output(testCtx.t, testCtx.opt, LOAD_BALANCER_IP)
		assert.NotNil(testCtx.t, loadBalancerIP, errMsg)
		assert.NotEmpty(testCtx.t, loadBalancerIP, errMsg)
		testCtx.saveString(LOAD_BALANCER_IP, loadBalancerIP)
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