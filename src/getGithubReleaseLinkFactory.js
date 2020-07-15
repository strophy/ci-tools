const semver = require('semver');

/**
 * @param {GitHub} githubClient
 *
 * @return {getGithubReleaseLink}
 */
function getGithubReleaseLinkFactory(githubClient) {
  /**
   * Get GitHub release link by package version and repo link
   *
   * @typedef getGithubReleaseLink
   *
   * @param {string} packageVersion
   * @param {string} repositoryPath
   *
   * @return {Promise<string>}
   */
  async function getGithubReleaseLink(packageVersion, repositoryPath) {
    const [repoUser, repoName] = repositoryPath.split('/');

    const suiteVersion = semver.coerce(packageVersion);

    const { data: releases } = await githubClient.getRepo(repoUser, repoName)
      .listReleases();

    const [matchingRelease] = releases
      .sort((releaseA, releaseB) => (
        semver.compare(releaseB.tag_name, releaseA.tag_name)
      ))
      .filter((release) => {
        const releaseVersion = semver.coerce(release.tag_name);

        return semver.satisfies(
          `${releaseVersion.major}.${releaseVersion.minor}.${releaseVersion.patch}`,
          `${suiteVersion.major}.${suiteVersion.minor}`,
        );
      });

    if (!matchingRelease) {
      throw new Error(
        `No matching releases found for version ${packageVersion} in ${repositoryPath}`,
      );
    }

    return matchingRelease.tarball_url;
  }

  return getGithubReleaseLink;
}

module.exports = getGithubReleaseLinkFactory;
