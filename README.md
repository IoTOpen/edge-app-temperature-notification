# edge-app-temperature-notification

Edge app for sending notifications when temperatures are under or over a set value with an optional delay.

Input parameters are:
```
{
  "functions": [1,2,3,4]
  "overOrUnder: "under",
  "threshold": 10,
  "delay": 5,
  "notificationOutput": 19
}
```

Notifications are sent with the payload:
```
{
  "function": <function that triggered the notification>
  "msg": <mqtt message that triggered the notification>
  "last_msg": <last mqtt message of the function that triggered the notification>
  "threshold": <configured threshold for reference>
}
```

If `delay` is configured to be 0, a notification is instantly sent when a temperature is outside the configured parameters.
In this case the `last_msg` field is the same as `msg` field.

If `delay` is non-zero, the temperature has to be outside the configured parameters for `delay` minutes before a notification is sent.
Any value reported within the configured parameters will reset the timer, and no notification will be sent.
In this case `msg` will be the first message that were outside configured parameters and `last_msg` will be the last message sent before notification.
