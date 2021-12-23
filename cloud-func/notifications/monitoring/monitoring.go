package monitoring

import (
	"context"
	"encoding/json"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/git"
	. "github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/messages" //lint:ignore ST1001 ignore this!
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/senders"
	"github.com/webdevelop-pro/go-common/logger"

	"github.com/kelseyhightower/envconfig"
)

type config struct {
	senders.Config
	Channels senders.ChannelsArray `required:"true" split_words:"true"`
}

type worker struct {
	config

	gitClient git.Client
}

type Incident struct {
	ConditionName string `json:"condition_name"`
	Resource      struct {
		Labels map[string]string `json:"labels"`
	} `json:"resource"`
	URL   string `json:"url"`
	State string `json:"state"`
}

type Alert struct {
	Incident Incident `json:"incident"`
}

func (a Alert) GetStatus() senders.MessageStatus {
	if a.Incident.State == "open" {
		return senders.Failure
	} else {
		return senders.Success
	}
}

func (a Alert) RenderTemplate(templateStr string) (string, error) {
	return RenderTemplate(templateStr, a)
}

// Subscribe consumes a Pub/Sub message.
func Subscribe(ctx context.Context, m PubSubMessage) error {
	var conf config
	log := logger.GetDefaultLogger(nil)

	err := envconfig.Process("", &conf)
	if err != nil {
		log.Error().Err(err).Msg("invalid config")
		return err
	}

	worker := NewWorker(conf)

	err = worker.ProcessEvent(ctx, m)
	if err != nil {
		log.Error().Err(err).Msg("invalid config")
	}

	return err
}

func NewWorker(conf config) worker {
	return worker{
		config: conf,
	}
}

func (w worker) ProcessEvent(ctx context.Context, m PubSubMessage) error {
	var alert Alert
	json.Unmarshal(m.Data, &alert)

	for _, channel := range w.config.Channels {
		err := senders.SendNotification(alert, channel, w, w.config.Config)
		if err != nil {
			return err
		}
	}

	return nil
}

func (w worker) CreateMessage(event interface{}) (string, error) {
	alert := event.(Alert)

	msgTemplate := "{{ .Incident.ConditionName }} - <{{ .Incident.URL }}|details>"

	return RenderTemplate(msgTemplate, alert)
}

func (w worker) CreateAttachment(event interface{}) (string, error) {
	alert := event.(Alert)

	attachment, err := json.MarshalIndent(alert.Incident.Resource.Labels, "", "  ")
	if err != nil {
		return "", err
	}

	attachmentStr := "```" + string(attachment) + "```"

	return attachmentStr, nil
}
