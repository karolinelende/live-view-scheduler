defmodule LiveViewScheduler.InterviewStages do
  import Ecto.Query
  alias LiveViewScheduler.Repo
  alias LiveViewScheduler.InterviewStage

  def get_by_id!(id) do
    from(is in InterviewStage, where: is.id == ^id)
    |> Repo.one!()
  end
end
