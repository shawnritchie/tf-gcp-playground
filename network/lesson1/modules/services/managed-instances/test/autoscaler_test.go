package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"os"
	"testing"
)

func TestTerraformInstanceGroupTest(t *testing.T) {
	t.Parallel()

	//os.Setenv("SKIP_bootstrap", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_validateInstances", "true")

	testCtx := createTestContext(t, "../../", "managed-instances/examples")
	vpcExampleDir := testCtx.testFolder

	test_structure.RunTestStage(t, "bootstrap", func() {
		loginProfile := gcp.GetLoginProfile(t, "shawn.ritchie@spinvadors.com")
		sshUserName := loginProfile.PosixAccounts[0].Username
		assert.NotEmpty(t, sshUserName)

		testCtx.opt = terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: vpcExampleDir,

			VarFiles: []string{"varfile.tfvars"},
		})

		test_structure.SaveTerraformOptions(t, vpcExampleDir, testCtx.opt)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraform.Destroy(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		terraform.InitAndApply(t, testCtx.opt)
	})

	test_structure.RunTestStage(t, "validateInstances", func() {
		projectId := terraform.Output(testCtx.t, testCtx.opt, "project_id")
		region := terraform.Output(testCtx.t, testCtx.opt, "region")
		instanceGroupName := terraform.Output(testCtx.t, testCtx.opt, "instance_group_name")

		group := gcp.FetchRegionalInstanceGroup(t, projectId, region, instanceGroupName)
		instances := group.GetInstanceIds(t)

		errMsg := "two instances should exist be contained in instance group"
		assert.NotEmpty(testCtx.t, instances, errMsg)
		assert.True(testCtx.t, len(instances) == 2, errMsg)
	})

}

type testContext struct {
	t          *testing.T
	opt        *terraform.Options
	testFolder string
}

func (ctx *testContext) assertValidResourceId(key string) {
	extractedResource := terraform.Output(ctx.t, ctx.opt, key)

	assert.NotNil(ctx.t, extractedResource, fmt.Sprintf("%s should not be null", key))
	assert.NotEmpty(ctx.t, extractedResource, fmt.Sprintf("%s should not empty", key))
}

func createTestContext(t *testing.T, rootFolder, terraformModuleFolder string) *testContext {
	cpTerraformFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformModuleFolder)
	if _, err := os.Stat(fmt.Sprintf("%s%s/.test-data/TerraformOptions.json", rootFolder, terraformModuleFolder)); err == nil {
		return &testContext{
			t: t,
			opt: test_structure.LoadTerraformOptions(t, cpTerraformFolder),
			testFolder: cpTerraformFolder,
		}
	}

	return &testContext{
		t: t,
		opt: nil,
		testFolder: cpTerraformFolder,
	}
}