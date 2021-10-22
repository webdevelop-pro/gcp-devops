package notifications

import (
	"context"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/cloudbuild"
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/messages"
)

// Subscribe consumes a Pub/Sub message.
func CloudBuildSubscribe(ctx context.Context, m messages.PubSubMessage) error {
	return cloudbuild.Subscribe(ctx, m)
}
