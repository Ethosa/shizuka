# author: Ethosa

when defined(debug):
  import logging

  var console_logger = newConsoleLogger(fmtStr="[$time]::$levelname - ")
  addHandler(console_logger)

  info("Compiled in debug mode.")


import
  VK/Vk,
  VK/LongPoll,
  VK/Keyboard,
  VK/Button,
  VK/Event,
  VK/TemplateElement,
  VK/Template,
  VK/Uploader,
  asyncdispatch,
  json
export
  Vk,
  LongPoll,
  Keyboard,
  Button,
  Event,
  TemplateElement,
  Template,
  Uploader,
  asyncdispatch,
  json
