defmodule ReqTokenBarrier.QueueUtilTest do
  use ExUnit.Case

  doctest ReqTokenBarrier.QueueUtil, import: true
  doctest ReqTokenBarrier.UserQuota.DurationParser, import: true
end
