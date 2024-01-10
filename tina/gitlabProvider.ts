import type { Gitlab as GitlabType } from "@gitbeaker/core";
import { Gitlab } from "@gitbeaker/rest";
import { Base64 } from "js-base64";
import type { GitProvider } from "@tinacms/datalayer";

export interface GitLabProviderOptions {
  owner: string;
  repo: string;
  token: string;
  branch: string;
  commitMessage?: string;
  rootPath?: string;
}

export class GitLabProvider implements GitProvider {
  gitlab: GitlabType;
  projectId: string;
  branch: string;
  rootPath?: string;
  commitMessage?: string;

  constructor(args: GitLabProviderOptions) {
    this.projectId = args.owner + "/" + args.repo;
    this.branch = args.branch;
    this.commitMessage = args.commitMessage;
    this.rootPath = args.rootPath;
    this.gitlab = new Gitlab({
      token: args.token,
    });
  }

  async onPut(key: string, value: string) {
    const path = this.rootPath ? `${this.rootPath}/${key}` : key;
    let fileExists = false;

    // Check if the file exists
    try {
      await this.gitlab.RepositoryFiles.show(this.projectId, path, this.branch);
      fileExists = true;
    } catch (e) {
      // File does not exist
    }

    // Create or update the file contents
    await this.gitlab.Commits.create(
      this.projectId,
      this.branch,
      this.commitMessage || "Edited with TinaCMS",
      [
        {
          action: fileExists ? "update" : "create",
          filePath: path,
          content: Base64.encode(value),
          encoding: "base64",
        },
      ]
    );
  }

  async onDelete(key: string) {
    const path = this.rootPath ? `${this.rootPath}/${key}` : key;
    let fileExists = false;

    // Check if the file exists
    try {
      await this.gitlab.RepositoryFiles.show(this.projectId, path, this.branch);
      fileExists = true;
    } catch (e) {
      // File does not exist
    }

    // Delete the file if it exists
    if (fileExists) {
      await this.gitlab.Commits.create(
        this.projectId,
        this.branch,
        this.commitMessage || "Edited with TinaCMS",
        [
          {
            action: "delete",
            filePath: path,
          },
        ]
      );
    } else {
      throw new Error(
        `Could not find file ${path} in project ${this.projectId}`
      );
    }
  }
}
