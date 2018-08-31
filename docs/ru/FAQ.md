# Часто задаваемые вопросы

**Q: Как создавать пользователей в loghouse?**

Создать пользователей и определить им права можно с помощью configMap `loghouse-user-config`.

По умолчанию configMap [`loghouse-user-config`](https://github.com/flant/loghouse/blob/master/charts/loghouse/templates/loghouse/loghouse-configmap.yaml) определяет одного пользователя - `admin` с полными правами:

```
data:
  user.conf: |-
    admin:
      - ".*"
```

Пример заведения нескольких пользователей с разными правами на `namespace`:

```
user.conf: |-
  admin:
    - ".*"
  p2p:
    - "frontpage-.*"
    - "p2p-.*"
    - "store-.*"
    - "healthchecker-.*"
    - "rightnow-.*"
  clubs2:
    - "clubs2-.*"
    - "shared-.*"
  mediasoft:
    - "bets-.*"
```  

Т.е. пользователь `mediasoft`, например, имеет доступ к `namespace` начинающимся с "bets-".

Т.к. аутентификация пользователей осуществляется с помощью basic-auth, их необходимо добавить в соответствующий `secret` `basic-auth`.

В результате, Loghouse на основании имени пользователя показывает логи разрешенных ему `namespace`.
