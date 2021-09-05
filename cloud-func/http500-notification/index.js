const { WebClient } = require('@slack/web-api');
  
// subscribe is the main function called by Cloud Functions.
module.exports.subscribe = async (event) => {
  const token = 'xoxp-XXX-YYY-ZZZ-IIIIIII';
  if (event.data === undefined) {
     return
  }
  const web = new WebClient(token);
  const data = eventToBuild(event.data);
  const message = createSlackMessage(data);
  try {
    const res = await web.chat.postMessage(message);
  } catch (err) {
    console.log("slack error", err);
  }
};

// eventToBuild transforms pubsub event message to a build object.
const eventToBuild = (data) => {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

// createSlackMessage create a message from a build object.
const createSlackMessage = (data) => {
  // console.log(JSON.stringify({"data": data}));
  const link = `<https://console.cloud.google.com/logs/query;query=insertId%3D%22${data?.insertId || ''}%22;timeRange=${data?.timestamp || ''}%2F${data?.timestamp || ''}?project=${PROJECT_ID}|${data?.resource?.labels?.container_name || '🔗'}>`
  const text = link +"\n```\n" + JSON.stringify(data?.httpRequest || data?.jsonPayload,null,2) + "\n```";
  const color = data?.severity === 'ERROR' || data?.jsonPayload?.level === 'error' ? '#B13333' : '#FBBC05';
  let message = {
    channel: 'http-errors',
    mrkdwn: true,
    attachments: [
      {
        color: color,
        fallback: text,
        text: text,
      }
    ]
  };
  return message
}
