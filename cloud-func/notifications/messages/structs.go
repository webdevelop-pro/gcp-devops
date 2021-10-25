package messages

import (
	"bytes"
	"text/template"
)

// PubSubMessage is the payload of a Pub/Sub event. Please refer to the docs for
// additional information regarding Pub/Sub events.
type PubSubMessage struct {
	Data []byte `json:"data"`
}

func RenderTemplate(templateStr string, data interface{}) (string, error) {
	temp := template.Must(template.New("message").Parse(templateStr))

	var result bytes.Buffer
	err := temp.Execute(&result, data)

	return result.String(), err
}
