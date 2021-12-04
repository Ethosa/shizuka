# author: Ethosa
{.push pure, size: sizeof(int8).}
type
  VkError* = object of ValueError
  LongpollError* = object of ValueError
  KeyboardError* = object of ValueError
  TemplateError* = object of ValueError
{.pop.}


template throw*(err: typedesc, msg: string) =
  ## Throws a new exception.
  raise newException(err, msg)