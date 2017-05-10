defmodule CodeCorps.GithubTesting do
  def create_issue(project, _attributes, _current_user) do
    case attributes["error_testing"] do
      true ->
        nil
      _ ->
        1 # Return github id
    end
  end
end
