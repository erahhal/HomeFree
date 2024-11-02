## HomeFree Self-Hosting Platform

**HomeFree** is a platform for easy, flexible, and progressive self-hosting to
liberate you from giant cloud providers.

> “These were rice paddies before they were parking lots. Rice was the basis for our society. Peasants planted the seeds and had highest status in the Confucian hierarchy. As the Master said, “Let the producers be many and the consumers few.' When the Feed came in from Atlantis, from Nippon, we no longer had to plant, because the rice now came from the matter compiler. It was the destruction of our society. When our society was based upon planting, it could truly be said, as the Master did, “Virtue is the root; wealth is the result.' But under the Western ti, wealth comes not from virtue but from cleverness. So the filial relationships became deranged. Chaos,” Dr. X said regretfully, then looked up from his tea and nodded out the window. “Parking lots and chaos.”

― Neal Stephenson, The Diamond Age: Or, a Young Lady's Illustrated Primer

> Dr. X raised one hand a few inches from the tabletop, palm down, and pawed once at the air. Hackworth recognized it as the gesture that well-to-do Chinese used to dismiss beggars, or even to call bullshit on people during meetings. "They are wrong," he said. "They do not understand. They think of the Seed from a Western perspective. Your cultures--and that of the Coastal Republic--are poorly organized. There is no respect for order, no reverence for authority. Order must be enforced from above lest anarchy break out. You are afraid to give the Seed to your people because they can use it to make weapons, viruses, drugs of their own design, and destroy order. You enforce order through control of the Feed. But in the Celestial Kingdom, we are disciplined, we revere authority, we have order within our own minds, and hence the family is orderly, the village is orderly, the state is orderly. In our hands the Seed would be harmless."

― Neal Stephenson, The Diamond Age: Or, a Young Lady's Illustrated Primer

## Don't suckle the Feed. Cultivate the Seed.

## Building

```
make build-image
```

## Running

```
make run
```

## Adding a secret

```
nix-shell -p sops --run "sops secrets/authentik.yaml"
```

Then add a key or keys, e.g.

```
env-vars: |
     VAR1 = abc
     VAR2 = def
```

Then reference in Nix config as follows:

```
config.sops.secrets.app.env-vars.path
```

Or point directly to the path, e.g.
```
sops.secrets."app" = {
  owner = "homefree";
  path = "/run/secrets/app/env-vars";
  restartUnits = [ "app.service" ];
};
```
and reference the path in config

## Getting server key

After starting the vm using `make run`, run `make generate-sops-config`

Then, within the VM:

```
cd ~/nixcfg
make build
```

## Initializing Authentik

Browse to:

http://ha.homefree.lan:9000/if/flow/initial-setup/

## Changing password for Authentik

ak create_recovery_key 10 akadmin

## Setting up HAProxy to transparently proxy TSL requests to Caddy

https://forum.opnsense.org/index.php?topic=18538.msg84958#msg84958
