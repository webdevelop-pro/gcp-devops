package monitoring

import (
	"context"
	"encoding/json"
	"strings"

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

	log logger.Logger

	gitClient git.Client
}

type Incident struct {
	ConditionName string `json:"condition_name"`
	Resource      struct {
		Labels map[string]string `json:"labels"`
	} `json:"resource"`
	Metadata struct {
		UserLabels map[string]string `json:"user_labels"`
	} `json:"metadata"`
	Metric struct {
		Labels map[string]string `json:"labels"`
	} `json:"metric"`
	Group string `json:"-"`
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

	worker := NewWorker(conf, log)

	err = worker.ProcessEvent(ctx, m)
	if err != nil {
		log.Error().Err(err).Msg("invalid config")
	}

	return err
}

func NewWorker(conf config, log logger.Logger) worker {
	return worker{
		config: conf,
		log:    log,
	}
}

func (w worker) ProcessEvent(ctx context.Context, m PubSubMessage) error {
	var alert Alert
	json.Unmarshal(m.Data, &alert)

	if alert.Incident.Metric.Labels != nil {
		if id, ok := alert.Incident.Metric.Labels["check_id"]; ok {
			groups := strings.Split(id, "-")
			if len(groups) > 2 {
				alert.Incident.Group = groups[len(groups)-2]
			}
		}
	}

	for _, channel := range w.config.Channels {
		err := senders.SendNotification(alert, channel, w, w.config.Config)
		if err != nil {
			w.log.Warn().Err(err).Msgf("failed send notification to %s channel", channel.To)
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
