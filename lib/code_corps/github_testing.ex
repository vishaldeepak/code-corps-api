defmodule CodeCorps.GithubTesting do
  alias CodeCorps.{Task, Repo}

  def create_issue(task, _current_user, _github_owner, _github_repo) do
    send self(), {:create_issue, task.id}

    task
    |> Task.github_changeset(%{"github_id" => 1})
    |> Repo.update()
  end
end
