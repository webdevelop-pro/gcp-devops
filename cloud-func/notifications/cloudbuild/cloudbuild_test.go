// Package p contains a Pub/Sub Cloud Function.

package cloudbuild

import (
	"context"
	"testing"

	. "github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/messages" //lint:ignore ST1001 ignore this!
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/senders"

	"github.com/stretchr/testify/require"
)

func TestE2EProcessEvent(t *testing.T) {
	t.Parallel()

	worker := NewWorker(
		Config{
			Config: senders.Config{
				SlackToken: "xoxb-***", // https://api.slack.com/apps?new_app=1 -> App -> OAuth & Permissions
			},
			GithubAccessToken: "ghp_***", // https://github.com/settings/tokens
			GitRepoOwner:      "replier-ai",
			Channels: map[string][]senders.Channel{
				"all": {
					{
						Type: senders.Slack,
						To:   "test_slack",
					},
					// {
					// 	Type: Matrix,
					// 	To:   "https://matrix.***/api/v1/matrix/hook/***",
					// },
				},
			},
		},
	)

	err := worker.ProcessEvent(context.Background(), PubSubMessage{
		Data: []byte(`
			{
				"id": "ee57301f-580f-4563-b2c2-ae6f137fb91a",
				"status": "SUCCESS",
				"startTime": "2021-09-19T10:47:24.334389196Z",
				"finishTime": "2021-09-19T10:48:26.652347Z",
				"projectId": "replier-ai-dev",
				"logUrl": "https://console.cloud.google.com/cloud-build/builds/ee57301f-580f-4563-b2c2-ae6f137fb91a?project=639894471322",
				"substitutions": {
					"REVISION_ID": "9e1180c77d205fbfa9052bcfd493928c430033f0",
					"SHORT_SHA": "9e1180c",
					"BRANCH_NAME": "cloudbuild",
					"REPO_NAME": "payment-api",
					"COMMIT_SHA": "9e1180c77d205fbfa9052bcfd493928c430033f0",
					"_SERVICE_NAME": "payment-api",
					"REF_NAME": "cloudbuild",
					"TRIGGER_NAME": "pament-api",
					"TRIGGER_BUILD_CONFIG_PATH": "cloudbuild.yamsls"
				}
			}`,
		),
	})

	require.Nil(t, err)
}
