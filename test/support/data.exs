defmodule Bourne.Test.Data do
  alias Bourne.Test.{Repo, Actor, Movie, Credit}

  def insert! do
    cleese = Repo.insert!(%Actor{name: "John Cleese"})
    chapman = Repo.insert!(%Actor{name: "Graham Chapman"})
    idle = Repo.insert!(%Actor{name: "Eric Idle"})
    gilliam = Repo.insert!(%Actor{name: "Terry Gilliam"})
    jones = Repo.insert!(%Actor{name: "Terry Jones"})
    palin = Repo.insert!(%Actor{name: "Michael Palin"})

    the_holy_grail = Repo.insert!(%Movie{title: "Monty Python and the Holy Grail", year: 1975})
    life_of_brian = Repo.insert!(%Movie{title: "Life of Brian", year: 1979})
    meaning_of_life = Repo.insert!(%Movie{title: "The Meaning of Life", year: 1983})

    for actor <- [cleese, chapman, idle, gilliam, jones, palin] do
      for movie <- [the_holy_grail, life_of_brian, meaning_of_life] do
        Ecto.build_assoc(actor, :credits, movie_id: movie.id) |> Repo.insert!
      end
    end

    :ok
  end
end
