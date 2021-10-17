package senders

import (
	"github.com/slack-go/slack"
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/git"
)

type SlackSender struct {
	Token     string `required:"true" split_words:"true"`
	GitClient git.Client
}

func (sl SlackSender) SendToSlack(message, channel string, status MessageStatus) error {
	attachment := slack.Attachment{
		Color: StatusColor[status],
		Text:  message,
	}

	api := slack.New(sl.Token)

	_, _, err := api.PostMessage(
		channel,
		slack.MsgOptionAttachments(attachment),
	)

	return err
}
