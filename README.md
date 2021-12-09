<div align="center">

# Shizuka
### The Nim framework for VK

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/ellerbrock/open-source-badges/)
[![Nim language-plastic](https://github.com/Ethosa/shizuka/blob/nightly/nim_plastic.svg)](https://github.com/Ethosa/shizuka/blob/nightly/nim_plastic.svg)
[![License: MIT](https://img.shields.io/github/license/Ethosa/shizuka)](https://github.com/Ethosa/shizuka/blob/master/LICENSE)
[![test](https://github.com/Ethosa/shizuka/workflows/test/badge.svg)](https://github.com/Ethosa/shizuka/actions)

#### Stable version - 1.0.0

</div>

## Install
```nim
nimble install shizuka
```

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
    var
      vk = newVk(8123456789, "mypassword")
      lp = newLongpoll(vk)

    vk@message_new(event):  # real-time events handler
      echo event

    lp.run()  # starts to listen longpoll.
    ```

## Debug mode
For enable debug mode compile with `-d:debug` or `--define:debug`.


<div align="center">

|[Wiki][]|[Docs][]|[Tests][]|
|--------|--------|---------|


Copyright 2021, Ethosa

</div>


[Wiki]:https://github.com/Ethosa/shizuka/wiki
[Docs]:https://ethosa.github.io/shizuka/shizuka.html
[Tests]:https://github.com/Ethosa/shizuka/tree/master/tests
