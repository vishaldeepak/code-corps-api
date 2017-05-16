defmodule CodeCorps.Services.TaskService do
  @moduledoc """
  Handles special CRUD operations for `CodeCorps.Task`.
  """

  alias CodeCorps.{Task, Project, Repo}

  @spec create_task(Plug.Conn.t, map) :: {:ok, Task.t} | {:error, Ecto.Changeset.t}
  def create_task(conn, attributes) do
    changeset = %Task{} |> Task.create_changeset(attributes)
    case Repo.insert(changeset) do
      {:ok, task} ->
        project = Project |> Repo.get(attributes["project_id"])
        if project.github_id do
          current_user = Guardian.Plug.current_resource(conn)
          github().create_issue(task, current_user, project.github_owner, project.github_repo)
        else
          {:ok, task}
        end
      {:error, changeset} -> {:error, changeset}
    end
  end

  @spec github() :: CodeCorps.Github | CodeCorps.GithubTesting
  defp github do
    Application.get_env(:code_corps, :github)
  end
end
