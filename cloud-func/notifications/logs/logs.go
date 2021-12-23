package logs

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

type LogRecord struct {
	Severity    string `json:"severity"`
	Timestamp   string `json:"timestamp"`
	InsertID    string `json:"insertId"`
	TextPayload string `json:"textPayload"`

	JsonPayload struct {
		Component   string `json:"component"`
		Message     string `json:"message"`
		Error       string `json:"error"`
		Gpt3RespRaw string `json:"gpt3RespRaw"`
		Query       string `json:"query"`
	} `json:"jsonPayload"`

	Resource struct {
		Labels struct {
			ProjectID     string `json:"project_id"`
			PodName       string `json:"pod_name"`
			ContainerName string `json:"container_name"`
			Namespace     string `json:"namespace_name"`
			Location      string `json:"location"`
			ClusterName   string `json:"cluster_name"`
		} `json:"labels"`
	} `json:"resource"`
}

func getDefaultBody(lr *LogRecord) string {
	result, _ := json.MarshalIndent(struct {
		Message     string `json:"message"`
		Error       string `json:"error"`
		Namespace   string `json:"namespace"`
		TextPayload string `json:"textPayload"`
	}{
		Message:     lr.JsonPayload.Message,
		Error:       lr.JsonPayload.Error,
		Namespace:   lr.Resource.Labels.Namespace,
		TextPayload: lr.TextPayload,
	}, "", "  ")

	return string(result)
}

func (lr LogRecord) GetStatus() senders.MessageStatus {
	if lr.JsonPayload.Message == "" {
		return senders.Unknow
	} else {
		return senders.Failure
	}
}

func (lr LogRecord) RenderTemplate(templateStr string) (string, error) {
	return RenderTemplate(templateStr, lr)
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

	worker := worker{config: conf}

	err = worker.ProcessEvent(ctx, m)
	if err != nil {
		log.Error().Err(err).Msg("invalid config")
	}

	return err
}

func (w worker) ProcessEvent(ctx context.Context, m PubSubMessage) error {
	var logRecord LogRecord
	err := json.Unmarshal(m.Data, &logRecord)
	if err != nil {
		return err
	}

	for _, channel := range w.config.Channels {
		err := senders.SendNotification(logRecord, channel, w, w.config.Config)
		if err != nil {
			return err
		}
	}

	return nil
}

func (w worker) CreateMessage(event interface{}) (string, error) {
	lr := event.(LogRecord)

	serviceLink := "https://console.cloud.google.com/kubernetes/deployment/" +
		"{{ .Resource.Labels.Location }}/{{ .Resource.Labels.ClusterName }}/{{ .Resource.Labels.Namespace }}/" +
		"{{ .Resource.Labels.ContainerName }}/overview?project={{ .Resource.Labels.ProjectID }}"

	logLink := "https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Atimestamp%3D%22" +
		"{{ .Timestamp }}%22%0AinsertId%3D%22{{ .InsertID }}%22;timeRange=PT3H?project={{ .Resource.Labels.ProjectID }}"

	msgTemplate := "<" + serviceLink + "|{{ .Resource.Labels.ContainerName }}> - <" + logLink + "|full log>"

	if lr.JsonPayload.Message == "" {
		msgTemplate = "Invalid log format!!! Please configure logger for this app! " + msgTemplate
	}

	return RenderTemplate(msgTemplate, lr)
}

func (w worker) CreateAttachment(event interface{}) (string, error) {
	lr := event.(LogRecord)

	result, err := json.MarshalIndent(struct {
		Message     string `json:"message"`
		Error       string `json:"error"`
		Namespace   string `json:"namespace"`
		TextPayload string `json:"textPayload"`
	}{
		Message:     lr.JsonPayload.Message,
		Error:       lr.JsonPayload.Error,
		Namespace:   lr.Resource.Labels.Namespace,
		TextPayload: lr.TextPayload,
	}, "", "  ")

	if err != nil {
		return "", err
	}

	return string(result), nil
}
