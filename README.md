# environments

An automated deployment process for several Libero standard projects, targeting a single VM [infrastructure](https://github.com/libero/infrastructure) at first, instantiated in multiple environments.

## Deployment

To:

- `unstable`: every `master` build of this repository deploys the newest versions of the projects.
- `demo`: pushing a new `latest/*` tag (e.g. `latest/20190701`) to the `libero/environments` Github repository deploys the newest versions of the projects.

## Architecture

`deploy.sh` logs in into a target VM over SSH to run a deployment command that should be present there. The VM is expected to maintain state across deployments:

- storing the deployed project revision
- keeping any non-deployed project around
- keeping the last used revision of that non-deployed project as the revision to run

By default, `deploy.sh` uses `latest-revision.sh` to find out the most recent revision of each project to deploy. A future development is to allow specific versions to be passed in.

Eventually `deploy.sh` can accept new revisions of some projects passed as an argument, for example by [customizing its Travis CI build](https://docs.travis-ci.com/user/triggering-builds/#customizing-the-build-configuration).

### Remote script

The `remote-deploy.sh` script is checks out a repository like `sample-configuration`, and executes `docker-compose` with customized environment variables.

Some of the variables, like secrets, can be put in place by `infrastructure`. The variables such as the projects revisions should be passed in from here instead.

Every new deployment modifies one or more of the projects revisions, and restart the services in `docker-compose`.

### Keys

`keys/` contains SSH private keys to access the servers to deploy on. These keys are encrypted transparently using `git-crypt` so they should show in plain text after `git crypt unlock`.

Travis CI can access these keys because it has been added as one of the `git-crypt` users. Its `git-crypt` key is stored safely via [`travis encrypt`](https://docs.travis-ci.com/user/encrypting-files/). All new `keys/` items can be added transparently, Travis CI will be able to access them.

Refer to the [infrastructure repository documentation on secrets management](https://github.com/libero/infrastructure#secrets-management) for details on `git-crypt` usage.
