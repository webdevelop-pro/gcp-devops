package senders

import "encoding/json"

type Send func(msg, attachment, dst string, status MessageStatus) error

type MessageStatus string

var (
	Success       MessageStatus = "SUCCESS"
	Failure       MessageStatus = "FAILURE"
	Timeout       MessageStatus = "TIMEOUT"
	InternalError MessageStatus = "INTERNAL_ERROR"
	Unknow        MessageStatus = "UNKNOW"
)

var StatusColor = map[MessageStatus]string{
	Success:       "#34A853", // green
	Failure:       "#EA4335", // red
	Timeout:       "#FBBC05", // yellow
	InternalError: "#EA4335", // red
	Unknow:        "#707070", // gray44
}

type ChannelType string

const (
	Slack  ChannelType = "slack"
	Matrix ChannelType = "matrix"
)

type Channel struct {
	Type ChannelType `json:"type"`
	To   string      `json:"to"`
}

type ChannelsMap map[string][]Channel

type ChannelsArray []Channel

func (channels *ChannelsMap) Decode(value string) error {
	return json.Unmarshal([]byte(value), channels)
}

func (channels *ChannelsArray) Decode(value string) error {
	return json.Unmarshal([]byte(value), channels)
}
