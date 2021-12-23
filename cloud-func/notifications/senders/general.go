package senders

import (
	"fmt"
)

type Config struct {
	SlackToken string `required:"true" split_words:"true"`
}

type MessageCreator interface {
	CreateMessage(event interface{}) (string, error)
	CreateAttachment(event interface{}) (string, error)
}

type Event interface {
	GetStatus() MessageStatus
	RenderTemplate(templateStr string) (string, error)
}

func SendNotification(event Event, channel Channel, mc MessageCreator, cfg Config) error {
	message, err := mc.CreateMessage(event)
	if err != nil {
		return fmt.Errorf("failed create notification message: %w", err)
	}

	attachment, err := mc.CreateAttachment(event)
	if err != nil {
		return fmt.Errorf("failed create attachment for message: %w", err)
	}

	var routes = map[ChannelType]Send{
		Matrix: SendToMatrix,
		Slack:  SlackSender{Token: cfg.SlackToken}.SendToSlack,
	}

	to, err := event.RenderTemplate(channel.To)
	if err != nil {
		return err
	}

	err = routes[channel.Type](
		message,
		attachment,
		to,
		event.GetStatus(),
	)
	if err != nil {
		return fmt.Errorf("failed send notification: %w", err)
	}

	return nil
}
