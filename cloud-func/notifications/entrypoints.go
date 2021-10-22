package notifications

import (
	"context"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/cloudbuild"
)

// Subscribe consumes a Pub/Sub message.
func CloudBuildSubscribe(ctx context.Context, m cloudbuild.PubSubMessage) error {
	return cloudbuild.Subscribe(ctx, m)
}
