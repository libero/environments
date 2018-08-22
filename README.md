# sample-deployment

An automated deployment process for several Libero standard projects, targeting a single VM [infrastructure](https://github.com/libero/infrastructure) at first.

## Architecture

`deploy.sh` will log in into a target VM over SSH to run a deployment command that should be present there. The VM is expected to maintain state across deployments:

- storing the deployed project revision
- keeping any non-deployed project around
- keeping the last used revision of that non-deployed project as the revision to run

By default, `deploy.sh` will use `latest-revision.sh` to find out the most recent revision of each project to deploy.

Eventually `deploy.sh` can accept new revisions of some projects passed as an argument, for example by [customizing its Travis CI build](https://docs.travis-ci.com/user/triggering-builds/#customizing-the-build-configuration).
