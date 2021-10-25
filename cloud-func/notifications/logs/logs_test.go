// Package p contains a Pub/Sub Cloud Function.

package logs

import (
	"context"
	"testing"

	. "github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/messages" //lint:ignore ST1001 ignore this!
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/senders"

	"github.com/stretchr/testify/require"
)

func TestE2EProcessEvent(t *testing.T) {
	t.Parallel()

	worker := worker{
		config: config{
			Config: senders.Config{
				SlackToken: "xoxb-***", // https://api.slack.com/apps?new_app=1 -> App -> OAuth & Permissions
			},
			Channels: senders.ChannelsArray{
				{
					Type: senders.Slack,
					To:   "test_slack",
				},
			},
		},
	}

	err := worker.ProcessEvent(context.Background(), PubSubMessage{
		Data: []byte(exampleEvent),
	})

	require.Nil(t, err)
}

var exampleEvent = `
{
    "insertId": "v6ifxp4uptcir8q2",
    "jsonPayload": {
        "message": "test message",
        "error": "test error"
    },
    "resource": {
        "type": "k8s_container",
        "labels": {
            "pod_name": "acrepro-backend-549d59cc95-bfvjw",
            "location": "us-central1-c",
            "container_name": "acrepro-backend",
            "project_id": "acre-pro",
            "cluster_name": "dev",
            "namespace_name": "dev"
        }
    },
    "timestamp": "2021-10-25T11:01:14.913264202Z",
    "severity": "ERROR",
    "labels": {
        "k8s-pod/app": "acrepro-backend",
        "k8s-pod/logsNotifications": "true",
        "k8s-pod/pod-template-hash": "549d59cc95",
        "compute.googleapis.com/resource_name": "gke-dev-default-pool-92c46fc2-1t56"
    },
    "logName": "projects/acre-pro/logs/stderr",
    "receiveTimestamp": "2021-10-25T11:01:16.622489548Z"
}
`
