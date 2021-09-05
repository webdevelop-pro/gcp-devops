package notifications

import (
	"context"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/subscriptions"
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/subscriptions/cloudbuild"
)

// Subscribe consumes a Pub/Sub message.
func CloudBuildSubscribe(ctx context.Context, m subscriptions.PubSubMessage) error {
	return cloudbuild.Subscribe(ctx, m)
}
