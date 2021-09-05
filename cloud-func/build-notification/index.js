const { WebClient } = require('@slack/web-api');
const { Logging } = require('@google-cloud/logging');
const logging = new Logging();
const Log = logging.log("cloudfunctions.googleapis.com%2Fcloud-functions");
const LogMetadata = {
  severity: "INFO",
  type: "cloud_function",
  labels: {
    function_name: process.env.K_SERVICE,
    project: process.env.GCLOUD_PROJECT,
    region: process.env.FUNCTION_REGION
  }
};

// const runtimeConfig = require('cloud-functions-runtime-config');
const humanizeDuration = require('humanize-duration');
const { Octokit } = require("@octokit/rest");

const repoOwner = "acretrader";
const github_token = 'ASK_SERGEY_ABOUT_IT';
const slack_token = 'ASK_SERGEY_ABOUT_IT';

let github = new Octokit({
  auth: github_token,
});

const DEFAULT_COLOR = '#4285F4'; // blue
const STATUS_COLOR = {
  'QUEUED': DEFAULT_COLOR,
  'WORKING': DEFAULT_COLOR,
  'SUCCESS': '#34A853', // green
  'FAILURE': '#EA4335', // red
  'TIMEOUT': '#FBBC05', // yellow
  'INTERNAL_ERROR': '#EA4335', // red
};

const CHANNELS = {
  'coming-soon': 'frontend_ci',
  'acrepro': 'acrepro-dev',
  'investment-go': 'investment',
  'documentation': 'doc',
  'e2e': 'end2end-tests',
  'frontend': 'frontend_ci',
  'frontend-vue3': 'frontend_ci',
  'email-sender': 'email',
  'unknown': 'devops',
};

// subscribe is the main function called by Cloud Functions.
module.exports.subscribe = async (event) => {
  // Only do slack notification if the current status is in the status list.
  // Add additional statues to list if you'd like:
  // QUEUED, WORKING, SUCCESS, FAILURE,
  // INTERNAL_ERROR, TIMEOUT, CANCELLED
  const status = ['SUCCESS', 'FAILURE', 'INTERNAL_ERROR', 'TIMEOUT'];
  if (status.indexOf(event.attributes.status) !== -1) {
    // const token = await runtimeConfig.getVariable('builder-config', 'slack_token')
    Log.write(Log.entry(LogMetadata, {msg: 'input event', data: event}));
    if (event.data === undefined) {
      return
    }
    const web = new WebClient(slack_token);
    const build = eventToBuild(event.data);
    let fields = [`Build <${build.logUrl}|${build.status}>`];
    let service = 'unknown';
    let commit = '0000000';
    let commitShort = commit;
    let branch = 'dev';
    let repoName = 'unknown';
    if (build.sourceProvenance && build.sourceProvenance.resolvedRepoSource && build.substitutions) {
      service = build.substitutions['_SERVICE_NAME'];
      commit = build.sourceProvenance.resolvedRepoSource.commitSha;
      repoName = build.sourceProvenance.resolvedRepoSource.repoName;
      commitShort = commit.substring(0, 7);
      if (build.source && build.source.repoSource && build.source.repoSource.branchName) {
        branch = build.source.repoSource.branchName;
      } else {
        branch = build.substitutions['BRANCH_NAME'];
      }
    } else if (build.substitutions && build.substitutions['COMMIT_SHA']) {
      service = build.substitutions['REPO_NAME'];
      repoName = build.substitutions['REPO_NAME'];
      commit = build.substitutions['COMMIT_SHA'];
      commitShort = build.substitutions['SHORT_SHA'];
      branch = build.substitutions['BRANCH_NAME'];
    }
    let ghCommit
    try {
      ghCommit = await github.repos.getCommit({
        owner: repoOwner,
        repo: repoName.replace(`github-${repoOwner}-`, '').replace(`github_${repoOwner}_`, ''),
        ref: commit,
      })
    } catch (err) {
      Log.write(Log.entry({ ...LogMetadata, severity: 'ERROR' }, { msg: 'failed to get github commit info', err: err }));
    }
    Log.write(Log.entry({ ...LogMetadata, severity: 'INFO' }, { msg: 'github commit info', data: ghCommit }));

    if (service === 'unknown' && build.substitutions && build.substitutions['_SERVICE_NAME']) {
      service = build.substitutions['_SERVICE_NAME'];
    }
    if (service !== 'unknown') {
      fields.push(`, Commit: <https://github.com/acretrader/${service}/commit/${commit}|${service}/${branch} - ${commitShort}>`);
    }
    if (service === 'e2e') {
      fields.push(`<https://e2e-reports.acretrader.com/${build.id}/report/report.html|report>,`);
    }
    fields.push(`\nAuthor: <https://github.com/${ghCommit.data.author.login}|${ghCommit.data.author.login}>`)
    fields.push(`, Branch: <https://github.com/acretrader/${service}/${branch}|${branch}>`)
    if (ghCommit !== undefined && ghCommit !== null && ghCommit.data !== null && ghCommit.data.author !== null && ghCommit.data.commit !== null) {
      fields.push(`\n${ghCommit.data.commit.message}`)
    }
    fields.push(`\nDuration: ` + humanizeDuration(new Date(build.finishTime) - new Date(build.startTime)));
    let text = fields.join(' ');
    let message = {
      channel: '#' + (CHANNELS[service] || service),
      mrkdwn: true,
      attachments: [
        {
          color: STATUS_COLOR[build.status] || DEFAULT_COLOR,
          fallback: text,
          text: text,
        }
      ]
    };

    try {
      Log.write(Log.entry({ ...LogMetadata, severity: 'INFO' }, { msg: 'slack msg', data: message }));
      const res = await web.chat.postMessage(message);
      Log.write(Log.entry({ ...LogMetadata, severity: 'INFO' }, { msg: 'slack response', data: res }));
    } catch (err) {
      Log.write(Log.entry({ ...LogMetadata, severity: 'ERROR' }, { msg: 'slack error', err: err }));
    }
  }
  {
    const statusMap = {
      QUEUED: "pending",
      WORKING: "pending",
      SUCCESS: "success",
      FAILURE: "failure",
      CANCELLED: "failure",
      TIMEOUT: "error",
      INTERNAL_ERROR: "error"
    }
    build = eventToBuild(event.data)

    const {
      id,
      projectId,
      status,
      steps,
      images,
      sourceProvenance: {
        resolvedRepoSource: repoSource
      },
      logUrl,
      tags,
      createTime,
      finishTime,
    } = build
    const ghStatus = statusMap[status]

    if (!repoSource || !ghStatus) {
      Log.write(Log.entry({ ...LogMetadata, severity: 'WARNING' }, { msg: 'skipping status update', data: {repoSource: repoSource, ghStatus: ghStatus} }));
      return
    }

    const ghRepo = repoSource.repoName.replace(`github-${repoOwner}-`, '').replace(`github_${repoOwner}_`, '')
    const ghContext = `Build`

    const lastStep = steps.filter(s => s.timing && s.timing.startTime).pop()
    const failureDescription = (ghStatus === 'failure' || ghStatus === 'error')
        ? ' · ' + (lastStep ? `${lastStep.id} ` : '') + status.toLowerCase()
        : ''
    const ghDescription = (
        createTime && finishTime
            ? secondsToString((new Date(finishTime) - new Date(createTime)) / 1000) + failureDescription
            : images && images.length > 0
                ? `${images.join('\n')}`
                : ''
    ).substring(0, 140)

    Log.write(Log.entry({ ...LogMetadata, severity: 'INFO' }, { msg: 'github status update data', data: {
        status: status,
        ghStatus: ghStatus,
        ghRepo: ghRepo,
        repoSource: repoSource,
        ghContext: ghContext,
        tags: tags,
        ghDescription: ghDescription,
        createTime: createTime,
        finishTime: finishTime,
        images: images,
      } }));


    let request = {
      owner: repoOwner,
      repo: ghRepo,
      sha: repoSource.commitSha,
      state: ghStatus,
      target_url: logUrl,
      description: ghDescription,
      context: ghContext
    }
    Log.write(Log.entry({ ...LogMetadata, severity: 'INFO' }, {msg: 'github status update request', data: request}));

    github.repos.createStatus(request)
  }
};

// eventToBuild transforms pubsub event message to a build object.
const eventToBuild = (data) => {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

const secondsToString = (s) => {
  const years = Math.floor(s / 31536000)
  const days = Math.floor((s % 31536000) / 86400)
  const hours = Math.floor(((s % 31536000) % 86400) / 3600)
  const minutes = Math.floor((((s % 31536000) % 86400) % 3600) / 60)
  const seconds = Math.floor((((s % 31536000) % 86400) % 3600) % 60)

  return `${years}y ${days}d ${hours}h ${minutes}m ${seconds}s`
      .replace(/^(0[ydhm] )*/g, '')
}
