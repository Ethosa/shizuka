<h1 align="center">Shizuka</h1>
<div align="center">The Nim framework for VK

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/ellerbrock/open-source-badges/)
[![Nim language-plastic](https://github.com/Ethosa/yukiko/blob/master/nim-lang.svg)](https://github.com/Ethosa/yukiko/blob/master/nim-lang.svg)
[![License: MIT](https://img.shields.io/github/license/Ethosa/shizuka)](https://github.com/Ethosa/shizuka/blob/master/LICENSE)
<h4>Latest version - 0.2.4</h4>
<h4>Stable version - 0.2.4</h4>
</div>

## Getting started
- Install via nimble: `nimble install shizuka`
- Install via git: `nimble install https://github.com/Ethosa/shizuka` 

## Features
-   Calling any VK API method.
-   Convenient working with longpoll.
-   Uploader.
-   Fully async.
-   VK keyboards and templates.
-   Very simple usage
    ```nim
    import shizuka

    # auth
    var vk = Vk("8123456789", "mypassword")

    vk@message_new(event):  # real-time events handler
      echo event

    vk.start_listen()  # starts to listen longpoll.
    ```

## Debug mode
For enable debug mode compile with `-d:debug` or `--define:debug`.

## FAQ
*Q*: Where can I learn this library?  
*A*: You can learn it in [wiki](https://github.com/Ethosa/shizuka/wiki).

*Q*: How can I help to develop this library?  
*A*: You can put a star :star: on this repository :3.

*Q*: Where can I read the documentation about this library?  
*A*: You can see the [docs](https://ethosa.github.io/shizuka/shizuka/shizuka.html)


<div align="center">
  Copyright 2020, Ethosa
</div>
