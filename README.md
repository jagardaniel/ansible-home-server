## ansible-home-server

A repository with some Ansible playbooks for my home server, mostly for documentation purposes. The server runs Debian Stable and is mainly used as a basic router (nftables/Kea DHCP/unbound). The roles are not intended to cover all available configuration options and the vault file for production is not included in the repository.

I use a simple VM as "development" environment (`inventories/development`) to try out the roles before I apply them to my physical server (`inventories/production`).

### Run Ansible

Ansible will target the development environment as default. This means that it will use the host and group vars files under `inventories/development`. For example, ping the host:

```bash
$ ansible -m ansible.builtin.ping all
192.168.0.80 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

To target the "real" server instead we need to specify the production inventory with `-i`:

```bash
$ ansible -i inventories/production -m ansible.builtin.ping all
192.168.0.1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Apply all roles. Ask for the become password with `-K`:

```bash
$ ansible-playbook site.yml -K
[...]
```

Apply all roles in the production environment. Also ask for the vault password (`-J`):

```bash
$ $ ansible-playbook -i inventories/production site.yml -K -J
[...]
```

Only run container related roles in production:

```bash
$ $ ansible-playbook -i inventories/production containers.yml -K -J
[...]
```
