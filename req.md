want create infrastructure as code for a new whole VPS. 
this current ubuntu System with docker containers.
examine my docker structure.
on a new VPS i only want to clone a repo and run a script (.sh or ansible or both?)
(Maybe switch to sudo user and git clone …)

1. Put all my Docker stuff into a Git repo
example:
infra-vps/
  docker/
    n8n/
      docker-compose.yml
      .env.example
    openwebui/
      docker-compose.yml
      .env.example
    proxy/
      docker-compose.yml
      nginx/
        conf.d/...
  scripts/
    bootstrap.sh
    restore-data.sh
  docs/
    NOTES.md

2. Automate server bootstrap (users, SSH, firewall, Docker)
3. Data + config backups
i want to backup all data from all docker apps and Regularly back up those folders + DB dumps to somewhere not on that VPS.
for that make all important data (generated from the apps in the docker containers) live in predictable host folders.
my suggestion:
create one storage-root-folder (/srv) like this:
/srv/
  n8n/
    data/        # .n8n config, if sqlite etc.
    db/          # postgres data, if you use Postgres
  openwebui/
    data/
  nginx/
    data/        # certs, config (if using a proxy manager)

Decide where persistent data lives
Optionally add a “one-command restore” ritual.
4 change all the docker-compose.yml according to the new structure (easy to copy or make a backup) bind-mount
5. create a readme.md file with short descripion and how to do

