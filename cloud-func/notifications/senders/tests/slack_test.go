package senders

import (
	"github.com/webdevelop-pro/gcp-devops/go-common/senders"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestE2ESend_ToSlack_SuccessReturnNil(t *testing.T) {
	t.Parallel()

	// Uncomment this lines if your want check slack sender

	// var send senders.Send
	// send = senders.SlackSender{
	// 	Token: "xoxb-***", // https://api.slack.com/apps?new_app=1 -> App -> OAuth & Permissions
	// }.SendToSlack

	// for status, _ := range senders.StatusColor {
	// 	require.Nil(t, send("Test message - "+string(status), "test_slack", status))
	// }
}

func TestSend_ToSlack_InvalidToken_ReturnError(t *testing.T) {
	t.Parallel()

	var send senders.Send
	send = senders.SlackSender{
		Token: "invalid_token",
	}.SendToSlack

	require.NotNil(t, send("Test message", "tests", senders.Success))
}
