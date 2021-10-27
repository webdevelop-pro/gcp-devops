package cloudbuild

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/git"
	. "github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/messages" //lint:ignore ST1001 ignore this!
	"github.com/webdevelop-pro/gcp-devops/cloud-func/notifications/senders"
	"github.com/webdevelop-pro/go-common/logger"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	senders.Config
	Channels          senders.ChannelsMap `required:"true" split_words:"true"`
	GitRepoOwner      string              `required:"true" split_words:"true"`
	GithubAccessToken string              `required:"true" split_words:"true"`
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

func (e EventRecord) GetStatus() senders.MessageStatus {
	return senders.MessageStatus(e.Status)
}

// Subscribe consumes a Pub/Sub message.
func Subscribe(ctx context.Context, m PubSubMessage) error {
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
		log.Error().Err(err).Interface("conf", conf).Msg("invalid config")
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

func (w Worker) ProcessEvent(ctx context.Context, m PubSubMessage) error {
	var event EventRecord
	json.Unmarshal(m.Data, &event)

	if event.Status != "SUCCESS" && event.Status != "FAILURE" && event.Status != "TIMEOUT" {
		return nil
	}

	send := func(output []senders.Channel) error {
		for _, channel := range output {

			if strings.Contains(event.Substitutions.BranchName, "/") {
				// Do not show notifications for side branches, like feat/, fix/, doc/ and so on
				return nil
			}

			err := senders.SendNotification(event, channel, w, w.Config.Config)
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

func (w Worker) CreateMessage(e interface{}) (string, error) {
	event := e.(EventRecord)

	duration := event.FinishTime.Sub(event.StartTime)

	commit, err := w.gitClient.GetCommit(event.Substitutions.RepoName, event.Substitutions.CommitSha)
	if err != nil {
		return "", err
	}

  /*
  log := logger.GetDefaultLogger(nil)
  log.Info().Interface("event", event).Msg("e")
  log.Info().Interface("commit", commit).Msg("c")
  */

	msgTemplate := "Build <{{ .Event.LogURL }}|{{ .Event.Status }}>, " +
		"Commit: <{{ .Commit.URL }}|{{ .Event.Substitutions.ShortSha }}>" +
		"\n" +
		"Author: <https://github.com/{{ or .Commit.AuthorName .Commit.AuthorLogin }}|{{ .Commit.AuthorName }}>, Branch: <https://github.com/{{ .Event.Substitutions.RepoName }}/tree/{{ .Event.Substitutions.BranchName }}|{{ .Event.Substitutions.BranchName }}>" +
		"\n" +
		"Duration: {{ .Duration }}\n\n" +
		"{{ .Commit.Message }}"

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

func (w Worker) CreateAttachment(e interface{}) (string, error) {
	return "", nil
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
