package senders

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type MatrixPayload struct {
	Text        string `json:"text"`
	IconUrl     string `json:"icon_url,omitempty"`
	Format      string `json:"format"`
	DisplayName string `json:"displayName"`
}

func SendToMatrix(message, webhook string, status MessageStatus) error {
	payload := MatrixPayload{
		Text:        message,
		Format:      "html",
		DisplayName: "Build Bot",
	}

	body, _ := json.Marshal(payload)
	req, err := http.NewRequest(http.MethodPost, webhook, bytes.NewBuffer(body))
	if err != nil {
		return err
	}

	req.Header.Add("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}

	buf := new(bytes.Buffer)
	buf.ReadFrom(resp.Body)

	var respBody map[string]bool
	err = json.Unmarshal(buf.Bytes(), &respBody)
	if err != nil {
		return fmt.Errorf("failed parse matrix response %s", buf.String())
	}

	if value, ok := respBody["success"]; ok && !value {
		return fmt.Errorf("non-ok response returned from Matrix %s", buf.String())
	}

	return nil
}
