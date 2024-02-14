defmodule ReqTokenBarrier.QueueUtil do
  defstruct queue: nil, items_wanted: nil, items: nil, items_count: nil

  @doc ~S"""
  Pop the top n items from the queue.

  ## Examples

    iex> # Create a queue with 5 items ([1,2,3,4,5])
    iex> items_in_queue = 5
    iex> queue = 
    ...>    1..items_in_queue
    ...>    |> Enum.reduce(:queue.new(), fn client, queue -> :queue.in(client, queue) end)
    iex>
    iex>
    iex> items_wanted = 9
    iex> {:partial, %{items_count: 5, items: [1,2,3,4,5], items_wanted: 4}} = 
    ...>    queue |> out_top_items(items_wanted)
    iex>
    iex> items_wanted = 5
    iex> {:ok, %{items_count: 5, items: [1,2,3,4,5]}} = 
    ...>    queue |> out_top_items(items_wanted)
    iex> 
    iex> items_wanted = 3  # Now we take 3 items out, leaving 2 in the queue
    iex> {:ok, %{items_count: 3, items: [1,2,3], queue: queue}} = 
    ...>    queue |> out_top_items(items_wanted)
    iex> 
    iex> items_wanted = 2  # Now we take the remaining 2 items out
    iex> {:ok, %{items_count: 2, items: [4,5], queue: queue}} = 
    ...>     queue |> out_top_items(items_wanted)
    iex> 
    iex> items_wanted = 10
    iex> {:partial, %{items_count: 0, items: [], items_wanted: 10, queue: _queue}} = 
    ...>     queue |> out_top_items(items_wanted)
  """
  def out_top_items(queue, items_wanted) do
    out_top_items(%__MODULE__{queue: queue, items_wanted: items_wanted, items: [], items_count: 0})
  end

  defp out_top_items(%__MODULE__{
         queue: queue,
         items_wanted: 0,
         items: items,
         items_count: items_count
       }) do
    # Done when nothing is wanted
    {:ok, %__MODULE__{queue: queue, items: Enum.reverse(items), items_count: items_count}}
  end

  defp out_top_items(%__MODULE__{
         queue: queue,
         items: items,
         items_wanted: items_wanted,
         items_count: items_count
       }) do
    case :queue.out(queue) do
      {:empty, queue} ->
        # Done when the queue is empty
        {:partial,
         %__MODULE__{
           queue: queue,
           items_wanted: items_wanted,
           items: Enum.reverse(items),
           items_count: items_count
         }}

      {{:value, item}, queue} ->
        out_top_items(%__MODULE__{
          queue: queue,
          items_wanted: items_wanted - 1,
          items: [item | items],
          items_count: items_count + 1
        })
    end
  end

  def demo() do
    {items_in_queue, items_wanted, initial_queue} = {5, 9, :queue.new()}

    queue =
      1..items_in_queue
      |> Enum.reduce(initial_queue, fn client, queue -> :queue.in(client, queue) end)

    case queue |> out_top_items(items_wanted) |> IO.inspect(label: :x) do
      {:ok, %__MODULE__{queue: queue, items: items}} ->
        "Got all items I wanted. Items are #{inspect(items)}, remaining queue contains #{:queue.len(queue)}"

      {:partial,
       %__MODULE__{
         queue: queue,
         items_wanted: items_wanted,
         items: items,
         items_count: items_count
       }} ->
        "Got only #{items_count} items, still missing #{items_wanted}. Items are #{inspect(items)}, remaining queue contains #{:queue.len(queue)}"
    end
  end
end
