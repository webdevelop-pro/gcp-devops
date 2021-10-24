package senders

import (
	"github.com/slack-go/slack"
)

type SlackSender struct {
	Token string `required:"true" split_words:"true"`
}

func (sl SlackSender) SendToSlack(message, attachmentStr, channel string, status MessageStatus) error {
	if attachmentStr == "" {
		attachmentStr = message
		message = ""
	}

	attachment := slack.Attachment{
		Color:      StatusColor[status],
		Title:      message,
		MarkdownIn: []string{""},
		Text:       attachmentStr,
	}

	api := slack.New(sl.Token)

	_, _, err := api.PostMessage(
		channel,
		slack.MsgOptionAttachments(attachment),
	)

	return err
}
