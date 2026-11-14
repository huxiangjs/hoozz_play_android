///
/// Created on 2026/11/14
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

const String _logName = 'github_release';

///
/// Headers for the GitHub REST API.
///
const Map<String, String> _apiHeaders = {
  'Accept': 'application/vnd.github+json',
  'X-GitHub-Api-Version': '2022-11-28',
};

const Duration _apiTimeout = Duration(seconds: 15);

class GitHubReleaseError implements Exception {
  final String message;

  GitHubReleaseError(this.message);

  @override
  String toString() => 'GitHubReleaseError: $message';
}

///
/// An asset of a release. GitHub automatically adds the Source code
/// archives (zip/tar.gz) to the assets list as well; the APK is picked
/// out by [LatestRelease.apkAsset].
///
class ReleaseAsset {
  final String name;
  final String url;
  final int size; // Bytes

  ReleaseAsset(this.name, this.url, this.size);
}

///
/// The latest release of a GitHub repository.
///
/// App-side counterpart of the Python experiment
/// github_release_parse/parse_github_release.py: same API calls and
/// the same fallback rules (message from the tag commit when the
/// release body is empty, commit sha resolved through the tag ref when
/// target_commitish is a branch name).
///
class LatestRelease {
  final String name;
  final String tag;
  final String commitHash; // Full 40 char commit sha the tag points to
  final String message; // Release body, or the tag commit message if empty
  final String publishedAt; // ISO 8601
  final String htmlUrl;
  final List<ReleaseAsset> assets;

  LatestRelease({
    required this.name,
    required this.tag,
    required this.commitHash,
    required this.message,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
  });

  ///
  /// The first APK asset of the release, or null if there is none.
  ///
  ReleaseAsset? get apkAsset {
    for (ReleaseAsset asset in assets) {
      if (asset.name.endsWith('.apk')) return asset;
    }
    return null;
  }
}

Future<dynamic> _apiGet(
  http.Client client,
  String url, {
  bool required = true,
}) async {
  http.Response resp = await client
      .get(Uri.parse(url), headers: _apiHeaders)
      .timeout(_apiTimeout);

  if (resp.statusCode == 404) {
    if (!required) return null;
    throw GitHubReleaseError('404: resource not found -> $url');
  }
  if (resp.statusCode == 403 || resp.statusCode == 429) {
    throw GitHubReleaseError(
      '${resp.statusCode}: GitHub API rate limit hit '
      '(unauthenticated: 60 requests/hour per IP)',
    );
  }
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw GitHubReleaseError('${resp.statusCode}: request failed -> $url');
  }

  return json.decode(resp.body);
}

///
/// Resolve the full commit sha the [tag] points to.
///
/// target_commitish is usually the full sha already. When the release
/// was created from a branch it is the branch name, in which case the
/// tag ref is resolved:
///   GET /git/refs/tags/{tag}  -> object (type commit => sha is the
///   commit, type tag => one more step)
///   GET /git/tags/{sha}       -> object.sha (annotated tag)
///
Future<String> _resolveCommitSha(
  http.Client client,
  String apiBase,
  String tag,
  String targetCommitish,
) async {
  if (RegExp(r'^[0-9a-f]{40}$').hasMatch(targetCommitish)) {
    return targetCommitish;
  }

  dynamic tagRef = await _apiGet(
    client,
    '$apiBase/git/refs/tags/${Uri.encodeComponent(tag)}',
    required: false,
  );
  if (tagRef == null) return targetCommitish;

  Map<String, dynamic> obj = tagRef['object'];
  if (obj['type'] == 'commit') {
    // Lightweight tag: points directly to the commit
    return obj['sha'];
  }

  dynamic tagObj = await _apiGet(client, '$apiBase/git/tags/${obj['sha']}',
      required: false);
  if (tagObj == null) return targetCommitish;
  return tagObj['object']['sha']; // Annotated tag: object points to the commit
}

///
/// Fetch the latest release of the GitHub repository [owner]/[repo].
///
/// Returns null when the repository has no release (404).
/// Throws [GitHubReleaseError] on rate limits (403/429) or other failures.
///
Future<LatestRelease?> fetchLatestRelease(
  String owner,
  String repo, {
  http.Client? client,
}) async {
  final bool ownClient = client == null;
  final http.Client httpClient = client ?? http.Client();

  try {
    final String apiBase = 'https://api.github.com/repos/$owner/$repo';

    dynamic release = await _apiGet(httpClient, '$apiBase/releases/latest');

    String tag = release['tag_name'];
    String targetCommitish = (release['target_commitish'] ?? '').toString();
    String commitHash = await _resolveCommitSha(
      httpClient,
      apiBase,
      tag,
      targetCommitish,
    );

    // Message: release body first; when empty, GitHub shows the tag
    // commit message on the page, so fetch it
    String message = (release['body'] ?? '').toString().trim();
    if (message.isEmpty) {
      dynamic commit = await _apiGet(httpClient, '$apiBase/commits/$commitHash');
      message = (commit['commit']['message'] ?? '').toString().trim();
    }

    List<ReleaseAsset> assets = [];
    for (dynamic asset in (release['assets'] ?? [])) {
      assets.add(
        ReleaseAsset(
          asset['name'],
          asset['browser_download_url'],
          (asset['size'] ?? 0) as int,
        ),
      );
    }

    developer.log(
      'Latest release: ${release['name']} ($tag) '
      'commit: $commitHash, assets: ${assets.length}',
      name: _logName,
    );

    return LatestRelease(
      name: (release['name'] ?? '').toString(),
      tag: tag,
      commitHash: commitHash,
      message: message,
      publishedAt: (release['published_at'] ?? '').toString(),
      htmlUrl: (release['html_url'] ?? '').toString(),
      assets: assets,
    );
  } finally {
    if (ownClient) httpClient.close();
  }
}
