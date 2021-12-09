# author: Ethosa

{.push pure.}
type
  VkKind* = enum
    VkUser,
    VkGroup
  ButtonAction* = enum
    ButtonText = "text",
    ButtonLink = "open_link",
    ButtonLocation = "location",
    ButtonPay = "vkpay",
    ButtonApp = "open_app",
    ButtonCallback = "callback"
  ButtonColor* = enum
    ColorPrimary = "primary",
    ColorSecondary = "secondary"
    ColorNegative = "negative",
    ColorPositive = "positive"
  TElementAction* = enum
    TElementLink = "open_link"
    TElementPhoto = "open_photo"
{.pop.}
