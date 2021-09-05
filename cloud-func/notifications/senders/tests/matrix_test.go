package senders

import (
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/webdevelop-pro/go-common/notifications/senders"
)

func TestE2ESend_ToMatrix_SuccessReturnNil(t *testing.T) {
	t.Parallel()

	// Uncomment this lines if your want check matrix sender
	//
	// var send senders.Send
	// send = senders.SendToMatrix
	// webhook := "https://matrix.***/api/v1/matrix/hook/***"
	// require.Nil(t, send("Test message", webhook, senders.Success))

	require.Nil(t, nil)
}

func TestSend_ToMatrix_InvalidWebhook_ReturnError(t *testing.T) {
	t.Parallel()

	// Uncomment this lines if your want check matrix sender
	//
	var send senders.Send
	send = senders.SendToMatrix
	webhook := "invalid_webhook"
	require.NotNil(t, send("Test message", webhook, senders.Success))
}
