# author: Ethosa
when defined(debug):
  import logging

{.push pure, size: sizeof(int8).}
type
  VkError* = object of ValueError
{.pop.}


template throw*(err: typedesc, msg: string) =
  ## Throws a new exception.
  when defined(debug):
    error(msg)
  raise newException(err, msg)