// used in https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions?display=list
// to send notifications to slack depending on events that occur in one of three contexts:
// Elastic Beanstalk (EB)
// Relational Database Service (RDS)
// Elastic Beanstalk CloudWatch Alarms
var https = require("https");
var util = require("util");

exports.handler = function(event, context) {
  console.log(event);

  var subject;
  var message;
  var type;

  // Records field will exist if this invocation happens from SNS
  if (event.Records) {
    subject =  event.Records[0].Sns.Subject;
    message = event.Records[0].Sns.Message;
  }
  else {
    message = event.environment + ': ' + event.message;
    subject = event.subject;
    type = event.type;
  }

  var severity = "good";
  var slackS3IconBucketURI = "https://s3.amazonaws.com/giveone-devops-assets/";

  var postData = {
    "channel": "#dev",
    "username": "Elastic Beanstalk",
    "text": "*" + subject + "*",
    "icon_url": slackS3IconBucketURI + "eb.png"
  };

  try {
    if (type === "worker") {
      postData.username = "Worker";
      postData.icon_url = slackS3IconBucketURI + "giveone.png";
    }
    else {
      var jsonMessage = JSON.parse(message);
      if (subject.indexOf("RDS") !== -1) {
        // we have an RDS notification
        severity = "warning";
        postData.username = "RDS";
        postData.icon_url = slackS3IconBucketURI + "rds.png";

        // via http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.html
        var dangerMessages = [
          "RDS-EVENT-0031",
          "RDS-EVENT-0036",
          "RDS-EVENT-0035",
          "RDS-EVENT-0058",
          "RDS-EVENT-0079",
          "RDS-EVENT-0080",
          "RDS-EVENT-0007",
          "RDS-EVENT-0022",
          "RDS-EVENT-0006"
        ];

        var goodMessages = [
          "RDS-EVENT-0049",
          "RDS-EVENT-0050",
          "RDS-EVENT-0051",
          "RDS-EVENT-0001",
          "RDS-EVENT-0002"
        ];

        eventId = jsonMessage["Event ID"];
        identifierLink = jsonMessage["Identifier Link"];
        message = jsonMessage["Event Message"] + " on " + identifierLink;

        for (var dangerMessagesItem in dangerMessages) {
          if (eventId.indexOf(dangerMessages[dangerMessagesItem]) !== -1) {
            severity = "danger";
            break;
          }
        }

        // only check for good messages if necessary
        if (severity === "warning") {
          for (var goodMessagesItem in goodMessages) {
            if (eventId.indexOf(goodMessages[goodMessagesItem]) !== -1) {
              severity = "good";
              break;
            }
          }
        }
      }
      else {
        postData.username = "CloudWatch Alarm";
        postData.icon_url = slackS3IconBucketURI + "cloudwatch.png";
        message = jsonMessage.AlarmDescription + ": " + jsonMessage.NewStateReason;
        if (jsonMessage.NewStateValue === "ALARM") {
          severity = "danger";
        }
        else if (jsonMessage.NewStateValue === "OK") {
          severity = "good";
        }
        else {
          severity = "warning";
        }
      }
    }

  }
  catch (e) {
    console.log("Not JSON, so assuming Elastic Beanstalk default notification format");
    var dangerMessages = [
      " but with errors",
      " to RED",
      "During an aborted deployment",
      "Failed to deploy application",
      "Failed to deploy configuration",
      "has a dependent object",
      "is not authorized to perform",
      "Degraded to Severe",
      "Info to Severe",
      "Ok to Severe",
      "Stack deletion failed",
      "Unsuccessful command execution",
      "You do not have permission",
      "Your quota allows for 0 more running instance"];

    var warningMessages = [
      " aborted operation.",
      " to YELLOW",
      "Adding instance ",
      "Degraded to Info",
      "Deleting SNS topic",
      "is currently running under desired capacity",
      "Ok to Info",
      "Ok to Warning",
      "Severe to Degraded",
      "Ok to Degraded",
      "Pending to Degraded",
      "Info to Degraded",
      "Pending Initialization",
      "Removed instance ",
      "Rollback of environment"
      ];

    for (var dangerMessagesItem in dangerMessages) {
      if (message.indexOf(dangerMessages[dangerMessagesItem]) !== -1) {
        severity = "danger";
        break;
      }
    }

    // only check for warning messages if necessary
    if (severity === "good") {
      for (var warningMessagesItem in warningMessages) {
        if (message.indexOf(warningMessages[warningMessagesItem]) !== -1) {
          severity = "warning";
          break;
        }
      }
    }
  }

  postData.attachments = [
    {
      "color": severity,
      "text": message
    }
  ];

  var options = {
    method: "POST",
    hostname: "hooks.slack.com",
    port: 443,
    path: "/services/T464UQ0J2/B4QKMMNUD/4MKxhMfMeveE3tVlciwukD2w"
  };

  var req = https.request(options, function(res) {
    res.setEncoding("utf8");
    res.on("data", function (chunk) {
    context.done(null);
    });
  });

  req.on("error", function(e) {
    console.log("problem with request: " + e.message);
  });

  req.write(util.format("%j", postData));
  req.end();
};
