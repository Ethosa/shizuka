# author: Ethosa

const
  DEFAULT_VK_API*: string = "5.131"
  VK_API_URL*: string = "https://api.vk.com/"
  METHOD_VK_API_URL*: string = VK_API_URL & "method/"
  USER_LONGPOLL_URL*: string = "https://$1?act=a_check&key=$2&ts=$3&wait=25&mode=2&version=3"
  BOT_LONGPOLL_URL*: string = "$1?act=a_check&key=$2&ts=$3&wait=25&mode=2&version=3"
