package test

import (
	"context"
	"fmt"
	"github.com/go-ping/ping"
	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	t "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"google.golang.org/api/oslogin/v1"
	"os"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"
)

type testContext struct {
	t          *testing.T
	opt        *terraform.Options
	testFolder string
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

func (ctx *testContext) extractOutput(outputKey string) string {
	return terraform.Output(ctx.t, ctx.opt, outputKey)
}

func (ctx *testContext) extractIP(outputKey string) string {
	ip := ctx.extractOutput(outputKey)
	instanceExternalIP := extractFirstElementFromStringArray(ctx.t, ip)
	return instanceExternalIP
}

func (ctx *testContext) saveString(key,value string) {
	test_structure.SaveString(ctx.t, ctx.testFolder, key, value)
}

func (ctx *testContext) loadString(key string) string {
	return test_structure.LoadString(ctx.t, ctx.testFolder, key)
}

func (ctx *testContext) assertValidResourceId(key string) {
	extractedResource := terraform.Output(ctx.t, ctx.opt, key)

	assert.NotNil(ctx.t, extractedResource, fmt.Sprintf("%s should not be null", key))
	assert.NotEmpty(ctx.t, extractedResource, fmt.Sprintf("%s should not empty", key))
}

func pingHost(t t.TestingT, host string) *ping.Statistics {
	pinger, err := ping.NewPinger(host)
	if err != nil {
		t.Fatal(err)
	}

	pinger.Count = pingMaxRetries
	pinger.Timeout = pingTimeout
	err = pinger.Run()
	if err != nil {
		t.Fatal(err)
	}

	return pinger.Statistics()
}

func extractFirstElementFromStringArray(t *testing.T, arrayStr string) string {
	re := regexp.MustCompile("\\[(.*?)\\]")
	assert.Regexp(t, re, arrayStr, fmt.Sprintf("Failed to extract element from Array: %v", arrayStr))

	match := re.FindStringSubmatch(arrayStr)
	return strings.Split(match[1], ",")[0]
}

func testPingComputeInstanceViaBastionHost(t t.TestingT, bastionHost ssh.Host, host string) {
	output, err := ssh.CheckSshCommandE(t, bastionHost, fmt.Sprintf("ping -c 3 -t 3 %s", host))
	if err != nil {
		t.Fatal(err)
	}

	re := regexp.MustCompile(",(.*?) received")
	assert.Regexp(t, re, output, fmt.Sprintf("Ping request to host: %v fialed.\nOutput: %v", host, output))

	match := re.FindStringSubmatch(output)
	packetsReceived, err := strconv.Atoi(strings.TrimSpace(match[1]));
	if err != nil {
		t.Fatalf("Error trying to evaluate successfully packets received", err)
	}

	if packetsReceived < 1 {
		t.Fatalf("Expected at least 1 successfully received packet")
	}
}

func testEchoOnComputeInstance(t t.TestingT, bastionHost ssh.Host) {
	output, err := ssh.CheckSshCommandE(t, bastionHost, fmt.Sprintf("echo '%s'", SSHEchoText))
	if err != nil {
		t.Fatal(err)
	}

	if strings.TrimSpace(SSHEchoText) != strings.TrimSpace(output) {
		t.Fatalf("Expected: %s. Got: %s\n", SSHEchoText, output)
	}
}

func doWithRetryAndTimeoutE(t *testing.T, description string, maxRetries int, sshSleepBetweenRetries time.Duration, timeoutPerRetry time.Duration, action func() (string, error)) (string, error) {
	return retry.DoWithRetryE(t, description, maxRetries, sshSleepBetweenRetries, func() (string, error) {
		return retry.DoWithTimeoutE(t, description, timeoutPerRetry, action)
	})
}

func ImportSSHKeyE(t t.TestingT, user, project, key string) error {
	ctx := context.Background()
	service, err := gcp.NewOSLoginServiceE(t)
	if err != nil {
		return err
	}

	parent := fmt.Sprintf("users/%s", user)

	sshPublicKey := &oslogin.SshPublicKey{
		Key: key,
	}

	_, err = service.Users.ImportSshPublicKey(parent, sshPublicKey).ProjectId(project).Context(ctx).Do()
	if err != nil {
		return err
	}

	return nil
}