defmodule ReqTokenBarrier.UserQuota.DurationParser do
  @moduledoc """
  A module for parsing durations like `01:02:03` (1 hour, 2 minutes, 3 seconds) into milliseconds (3723000 in that case), and vice versa.
  """

  import NimbleParsec

  t_duration =
    integer(2)
    |> unwrap_and_tag(:hour)
    |> ignore(string(":"))
    |> concat(integer(2) |> unwrap_and_tag(:minute))
    |> ignore(string(":"))
    |> concat(integer(2) |> unwrap_and_tag(:seconds))

  defparsecp(:parse_duration, t_duration)

  @doc ~S"""
  Convert duration string to milliseconds.

  ## Examples

    iex> duration_string_to_millisecond("01:02:03")
    3723000
    iex> duration_string_to_millisecond("00:00:03")
    3000
  """
  def duration_string_to_millisecond(duration) do
    {:ok, [hour: hour, minute: minute, seconds: seconds], "", %{}, _, _} =
      parse_duration(duration)

    ((hour * 60 + minute) * 60 + seconds) * 1000
  end

  @doc ~S"""
  Convert milliseconds (rounded up to the next full second) to duration string.

  ## Examples

    iex> millisecond_to_duration_string(1)
    "00:00:01"
    iex> millisecond_to_duration_string(5003)
    "00:00:06"
    iex> millisecond_to_duration_string(3723001)
    "01:02:04"
  """
  def millisecond_to_duration_string(milli_sec) do
    seconds_rounded_up = Kernel.ceil(milli_sec / 1_000)

    {0, [s, m, h]} =
      Enum.reduce([3600, 60, 1], {seconds_rounded_up, []}, fn divisor, {n, acc} ->
        {n |> rem(divisor), [n |> div(divisor) | acc]}
      end)

    [h, m, s]
    |> Enum.map(fn i -> i |> Integer.to_string() |> String.pad_leading(2, "0") end)
    |> Enum.join(":")
  end
end
