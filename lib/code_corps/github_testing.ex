defmodule CodeCorps.GithubTesting do
  require Logger

  def create_issue(attributes, _project, _current_user) do
    case attributes["error_testing"] do
      true ->
        nil
      _ ->
        1 # Return github id
    end
  end

  def update_issue(task, attributes, _current_user) do
    case attributes["error_testing"] do
      true ->
        Logger.error "Could not update Task ID: #{task.id}. Error: Github error"
      _ ->
        nil
    end
  end
end
