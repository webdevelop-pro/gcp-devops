package cloudbuild

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"time"
  "strings"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/git"
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/senders"
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/subscriptions"
	"github.com/webdevelop-pro/go-common/logger"

	"github.com/kelseyhightower/envconfig"

	"text/template"
)

type ChannelType string

const (
	Slack  ChannelType = "slack"
	Matrix ChannelType = "matrix"
)

type ChannelsMap map[string][]Channel

type Channel struct {
	Type ChannelType `json:"type"`
	To   string      `json:"to"`
}

func (channels *ChannelsMap) Decode(value string) error {
	return json.Unmarshal([]byte(value), channels)
}

type Config struct {
	SlackToken        string      `required:"true" split_words:"true"`
	Channels          ChannelsMap `required:"true" split_words:"true"`
	GitRepoOwner      string      `required:"true" split_words:"true"`
	GithubAccessToken string      `required:"true" split_words:"true"`
}

type Worker struct {
	Config

	gitClient git.Client
}

type EventRecord struct {
	ID            string    `json:"id"`
	Status        string    `json:"status"`
	LogURL        string    `json:"logUrl"`
	StartTime     time.Time `json:"startTime"`
	FinishTime    time.Time `json:"finishTime"`
	ProjectId     string    `json:"projectId"`
	Substitutions struct {
		RepoName   string `json:"REPO_NAME"`
		CommitSha  string `json:"COMMIT_SHA"`
		ShortSha   string `json:"SHORT_SHA"`
		BranchName string `json:"BRANCH_NAME"`
	} `json:"substitutions"`
}

// Subscribe consumes a Pub/Sub message.
func Subscribe(ctx context.Context, m subscriptions.PubSubMessage) error {
	var conf Config
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

func NewWorker(conf Config) Worker {
	return Worker{
		Config: conf,
		gitClient: git.GithubClient{
			AccessToken: conf.GithubAccessToken,
			RepoOwner:   conf.GitRepoOwner,
		},
	}
}

func (w Worker) ProcessEvent(ctx context.Context, m subscriptions.PubSubMessage) error {
	var event EventRecord
	json.Unmarshal(m.Data, &event)

	if event.Status != "SUCCESS" && event.Status != "FAILURE" && event.Status != "TIMEOUT" {
		return nil
	}

	send := func(output []Channel) error {
		for _, channel := range output {
			err := w.sendNotification(event, channel)
			if err != nil {
				return err
			}
		}

		return nil
	}

	output, ok := w.Channels[event.Substitutions.RepoName]
	if ok {
		err := send(output)
		if err != nil {
			return err
		}
	}

	err := send(w.Channels["all"])
	if err != nil {
		return err
	}

	return nil
}

func (w Worker) sendNotification(event EventRecord, channel Channel) error {
  // Do not show notifications for side branches, like feat/, fix/, doc/ and so on
  if strings.Contains(event.Substitutions.BranchName, "/") == false { 
    message, err := w.createMessage(event)
    if err != nil {
      return fmt.Errorf("failed create notification message: %w", err)
    }

    routes := map[ChannelType]senders.Send{
      Matrix: senders.SendToMatrix,
      Slack:  senders.SlackSender{Token: w.SlackToken}.SendToSlack,
    }

    err = routes[channel.Type](
      message,
      channel.To,
      senders.MessageStatus(event.Status),
    )
    if err != nil {
      return fmt.Errorf("failed send notification: %w", err)
    }
  }

	return nil
}

func (w Worker) createMessage(event EventRecord) (string, error) {
	duration := event.FinishTime.Sub(event.StartTime)

	commit, err := w.gitClient.GetCommit(event.Substitutions.RepoName, event.Substitutions.CommitSha)
	if err != nil {
		return "", err
	}

	msgTemplate := "Build <{{ .Event.LogURL }}|{{ .Event.Status }}>," +
		"Commit: <{{ .Commit.URL }}|{{ .Event.Substitutions.RepoName }}/{{ .Event.Substitutions.BranchName }} - {{ .Event.Substitutions.ShortSha }}>" +
		"\n" +
		"Author: <https://github.com/{{ .Commit.AuthorLogin }}|{{ .Commit.AuthorName }}>, Branch: <https://github.com/{{ .Event.Substitutions.RepoName }}/tree/{{ .Event.Substitutions.BranchName }}>" +
		"\n" +
		"{{ .Commit.Message }}" +
		"\nDuration: {{ .Duration }}"

	return RenderTemplate(
		msgTemplate,
		struct {
			Config   Config
			Event    EventRecord
			Commit   git.Commit
			Duration string
		}{
			Config:   w.Config,
			Event:    event,
			Commit:   *commit,
			Duration: humanizeDuration(duration),
		})
}

func humanizeDuration(duration time.Duration) string {
	if duration.Seconds() < 60.0 {
		return fmt.Sprintf("%d sec", int64(duration.Seconds()))
	}
	if duration.Minutes() < 60.0 {
		remainingSeconds := math.Mod(duration.Seconds(), 60)
		return fmt.Sprintf("%d min %d sec", int64(duration.Minutes()), int64(remainingSeconds))
	}
	if duration.Hours() < 24.0 {
		remainingMinutes := math.Mod(duration.Minutes(), 60)
		remainingSeconds := math.Mod(duration.Seconds(), 60)
		return fmt.Sprintf("%d hours %d min %d sec",
			int64(duration.Hours()), int64(remainingMinutes), int64(remainingSeconds))
	}
	remainingHours := math.Mod(duration.Hours(), 24)
	remainingMinutes := math.Mod(duration.Minutes(), 60)
	remainingSeconds := math.Mod(duration.Seconds(), 60)
	return fmt.Sprintf("%d days %d hours %d min %d sec",
		int64(duration.Hours()/24), int64(remainingHours),
		int64(remainingMinutes), int64(remainingSeconds))
}

func RenderTemplate(templateStr string, data interface{}) (string, error) {
	temp := template.Must(template.New("message").Parse(templateStr))

	var result bytes.Buffer
	err := temp.Execute(&result, data)

	return result.String(), err
}
