<h1 align="center">shizuka</h1>
The Nim framework for VK

## Getting started
***Installing***: `nimble install https://github.com/Ethosa/shizuka`  
***Import***: `import shuzuka`

### Authorization

#### Sync
```nim
import shizuka
vk = Vk("88005553535", "qwertyuiop", debug=true)
```

#### Async
```nim
import asyncdispatch
import shizuka
vk = AVk("88005553535", "qwertyuiop", debug=true)
```

### Methods calling

#### Sync
```nim
var response = vk~users.get(user_ids="akihayase")
```

#### Async
```nim
var response = waitFor vk~users.get(user_ids="akihayase")
```
