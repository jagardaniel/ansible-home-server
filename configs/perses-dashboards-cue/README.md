This is an attempt to build dashboards for Perses with CUE SDK. Instructions how to set up a repository can be found here:
https://perses.dev/perses/docs/dac/getting-started/#getting-started-with-the-cue-sdk

### Example

```bash
# Build
$ percli dac build -f teamspeak3.cue -o json
Successfully built teamspeak3.cue at built/teamspeak3_output.json

# Deploy
$ percli apply -f built/teamspeak3_output.json
object "Dashboard" "teamspeak_3" has been applied in the project "home"
```
