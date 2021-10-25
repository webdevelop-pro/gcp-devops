// Package p contains a Pub/Sub Cloud Function.

package monitoring

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
    "incident": {
        "condition": {
            "conditionThreshold": {
                "aggregations": [
                    {
                        "alignmentPeriod": "60s",
                        "crossSeriesReducer": "REDUCE_MAX",
                        "groupByFields": [
                            "resource.label.namespace_name",
                            "resource.label.container_name",
                            "resource.label.cluster_name"
                        ],
                        "perSeriesAligner": "ALIGN_DELTA"
                    }
                ],
                "comparison": "COMPARISON_GT",
                "duration": "0s",
                "filter": "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\"",
                "trigger": {
                    "count": 1
                }
            },
            "displayName": "Kubernetes container restarted",
            "name": "projects/acre-pro/alertPolicies/3136798757679215862/conditions/3136798757679217293"
        },
        "condition_name": "Kubernetes container restarted",
        "ended_at": 1635101290,
        "incident_id": "0.m8u0mnh9byf4",
        "metadata": {
            "system_labels": {},
            "user_labels": {}
        },
        "metric": {
            "displayName": "Restart count",
            "labels": {},
            "type": "kubernetes.io/container/restart_count"
        },
        "observed_value": "0.000",
        "policy_name": "k8s-container-restarted",
        "resource": {
            "labels": {
                "cluster_name": "dev",
                "container_name": "acrepro-backend",
                "namespace_name": "dev",
                "project_id": "acre-pro"
            },
            "type": "k8s_container"
        },
        "resource_id": "",
        "resource_name": "acre-pro Kubernetes Container labels {project_id=acre-pro, cluster_name=dev, namespace_name=dev, container_name=acrepro-backend}",
        "resource_type_display_name": "Kubernetes Container",
        "scoping_project_id": "acre-pro",
        "scoping_project_number": 780026775853,
        "started_at": 1635101230,
        "state": "closed",
        "summary": "Restart count for acre-pro Kubernetes Container labels {project_id=acre-pro, cluster_name=dev, namespace_name=dev, container_name=acrepro-backend} returned to normal with a value of 0.000.",
        "threshold_value": "0",
        "url": "https://console.cloud.google.com/monitoring/alerting/incidents/0.m8u0mnh9byf4?project=acre-pro"
    },
    "version": "1.2"
}
`
