package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/stretchr/testify/assert"
)

// An example of how to test the simple Terraform module in examples/terraform-basic-example using Terratest.
func TestTerraformBasicExample(t *testing.T) {
	t.Parallel()

	projectName := "test"
	enableServices := []string{"compute.googleapis.com"}

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// website::tag::1::Set the path to the Terraform code that will be tested.
		// The path to where our Terraform code is located
		TerraformDir: "../examples",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"project_name": projectName,
			"service_api": enableServices,
		},

		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"varfile.tfvars"},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	})

	// website::tag::4::Clean up resources with "terraform destroy". Using "defer" runs the command at the end of the test, whether the test succeeds or fails.
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, opts)

	// website::tag::2::Run "terraform init" and "terraform apply".
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, opts)

	// Run `terraform output` to get the values of output variables
	actualProjectId := terraform.Output(t, opts, "project_id")

	// website::tag::3::Check the output against expected values.
	// Verify we're getting back the outputs we expect
	assert.NotNil(t, actualProjectId, "project_id should not be null")
	assert.NotEmpty(t, actualProjectId, "project_id should not be empty")
	assert.True(t, strings.HasPrefix(actualProjectId, actualProjectId), fmt.Sprintf("projectId should start with %s", actualProjectId))

	//$ gcloud config set project VALUE
	shell.RunCommand(t, shell.Command{
		Command: "gcloud",
		Args:    []string{"config", "set", "project", actualProjectId},
	})

	//$ gcloud services list --enabled
	cmd := shell.Command{
		Command: "gcloud",
		Args:    []string{"services", "list", "--enabled"},
		Env: map[string]string{
			"GCP_PROJECT": actualProjectId,
		},
	}

	if output, err := shell.RunCommandAndGetOutputE(t, cmd); err != nil {
		t.Error(err)
	} else {
		if !strings.Contains(output, "compute.googleapis.com") {
			t.Error("'compute.googleapis.com', wasn't enabled")
		}
	}
}