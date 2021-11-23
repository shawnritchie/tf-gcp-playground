package test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestTerraformComputeResourceExample(t *testing.T) {
	t.Parallel()

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// website::tag::1::Set the path to the Terraform code that will be tested.
		// The path to where our Terraform code is located
		TerraformDir: "../examples/private",

		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"varfile.tfvars"},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, opts)

	// website::tag::2::Run "terraform init" and "terraform apply".
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, opts)

	// Run `terraform output` to get the values of output variables
	actualComputeResourceId := terraform.Output(t, opts, "computer_resource_id")

	assert.NotNil(t, actualComputeResourceId, "computer_resource_id should not be null")
	assert.NotEmpty(t, actualComputeResourceId, "computer_resource_id should not empty")
}