Static quadlet files for podman until the podman role is updated to create quadlet files instead of generating systemd unit files (deprecated). The Podman version in Debian 12/bookworm does not support quadlet, only available from 13/trixie.

Place the quadlet files in ` ~/.config/containers/systemd/`, run `systemctl --user daemon-reload` and start the pod/container with `systemctl --user start name.service`.

One issue I have is that my pods and containers doesn't start correctly after a reboot and I see errors from pasta (rootless networking) "Couldn't set IPv4 route(s)". This is probably because it tries to bind ports to my internal IP address before the network address on the host is configured. Even with Restart=always and a few seconds cooldown between each restart I see weird behavior like the container is up and running but can't reach services on my host, or unable to reach the service inside the container.

Podman has a user service called `podman-user-wait-network-online.service` that is inserted as a dependecy for each pod/container service as default and it is supposed to wait until the network is online. This service was created because user services can not depend on system services. However on my server this service (it checks if network-online.target is active) activates before the network is actually up and running so it doesn't work. Here are two GitHub issues about the problem: https://github.com/containers/podman/issues/22197 and https://github.com/containers/podman/issues/24796

One comment suggested to override the `podman-user-wait-network-online.service` and wait until a successful ping instead and this seems to work for me. Another option is to put a 20-30 second sleep as ExecStartPre in the quadlet file but it doesn't feel as good.

So I ran `systemctl --user edit podman-user-wait-network-online.service` and inserted:

```
[Service]
ExecStart=
ExecStart=/bin/sh -c 'until ping -c 1 cloudflare.com; do sleep 5; done'
```

It should create an override.conf file that overrides the ExecStart. After a reboot, all user containers and pods should only start after the ping command is successful. And since ping requires both networking and DNS to work it should be enough to say that the network is actually "up and running". At least for me.

I also learned that mapping the host user to the containers user with `UserNS=keep-id....` (more convenient when it comes to file permissions) is less secure. We can use `podman unshare` to modify files with subuid/subgid file permissions.
