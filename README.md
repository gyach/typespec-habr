# Язык TypeSpec для создания API-документации
## TL;DR
- Подробная документация на сайте [typespec.io](https://typespec.io/).
- Инструмент позволяет упростить процесс документирования API за счёт использования нового языка TypeSpec (файлы с расширением \*.tsp) и плагина для VS Code.
- TypeSpec  умеет генерировать спецификации в форматах [OpenAPI v3.0.0](https://spec.openapis.org/oas/v3.0.0.html), [Protobuf](https://protobuf.com/docs/language-spec), [JSON Schema](https://json-schema.org/))
- [Лицензия MIT](https://github.com/microsoft/typespec/blob/main/LICENSE) даёт широкие возможности по использованию.
- [Мейнтейнер Microsoft](https://github.com/microsoft/typespec/) со стабильными релизами позволяет с достаточно высокой вероятностью гарантировать будущее развитие для этого языка.
- Есть возможность миграции существующего OpenAPI3 на TypeSpec с помощью [CLI-утилиты](https://typespec.io/docs/emitters/openapi3/cli/).
- В статье приведен базовый пример генерации спецификации, но возможности TypeSpec покрывают все  потребности любого проекта. В том числе за счет возможности расширения своими библиотеками. 
- Код из статьи и сама статья [есть на GitHub](https://github.com/gyach/typespec-habr).

## Из чего состоит решение?
1. CLI-утилита [@typespec/compiler](https://www.npmjs.com/package/@typespec/compiler) , которая компилирует tsp-файлы в целевые спецификации.
2. [Плагин для VS Code](https://marketplace.visualstudio.com/items?itemName=typespec.typespec-vscode), который умеет всё, что нужно для удобной работы с кодом на языке TypeSpec.
3. [Стандартные](https://typespec.io/docs/standard-library/built-in-decorators/) и дополнительные библиотеки декораторов и типов, с помощью которых происходит вся “магия”.
4. Эмиттеры, которые при компиляции генерируют спецификацию в целевые форматы.

## Как оно выглядит?

Для работы понадобится софт:
- [Node.js 20 LTS](https://nodejs.org/en/download/) и выше.
- [Visual Studio Code](https://code.visualstudio.com/) 

Можно клонировать [готовый проект с GitHub](https://github.com/gyach/typespec-habr) или создать пошагово новый nodejs-проект 
```bash
$ mkdir typespec-test && cd $_
$ npm init -y
```

Установить CLI-утилиту
```bash
$ npm i -D @typespec/compiler
```

Инициализировать проект TypeSpec
```bash
$ npx tsp init
TypeSpec compiler v0.62.0

✔ Folder '/home/gyach/dev/typespec-test' is not empty. Are you sure you want to initialize a new project here? … yes
✔ Please select a template › Generic REST API   min compiler ver: 0.62.0
Create a project representing a generic REST API
✔ Project name … typespec-test
✔ Do you want to generate a .gitignore file? … yes
✔ Update the libraries? › @typespec/http, @typespec/openapi3
TypeSpec init completed. You can run `tsp install` now to install dependencies..
Project created successfully.
```

Установить зависимости
```bash
$ npx tsp install
```

Установить плагин [TypeSpec for VS Code](https://marketplace.visualstudio.com/items?itemName=typespec.typespec-vscode)
### Файловая структура

#### tspconfig.yaml
Файл конфигурации нужен для компилятора, возможности приведены в [документации](https://typespec.io/docs/handbook/configuration/configuration/).
```yaml
# Коллекция эмиттеров - спецификаций в которые будет компилироваться проект
emit:
	# Генерация спецификации в OAS3
  - "@typespec/openapi3"
```

#### main.tsp
Основной файл TypeSpec – входная точка для компилятора при стандартной конфигурации.
```ts
// Импортируем необходимые библиотеки
import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

// using позволяет использовать декораторы без указания fully qualified names
using TypeSpec.Http;
using TypeSpec.Rest;
using TypeSpec.OpenAPI;

@service({
  title: "Users API",
})
@server("https://example.com", "Single server endpoint")

// Неймспейсы - это абстракция, которая позволяет организовать хранение моделей и эндпоинтов
namespace UsersService;

// Неймспейсы могут быть вложенными и декорированными
@route("/users")
@tag("Users")
namespace Users {
  // Эндпоинты
  @get()
  @summary("Возвращает список пользователей")
  op getUsersRegistry(): {
    @statusCode statusCode: 200;
    @body users: User[];
  };

  @get
  @summary("Возвращает пользователя по его ID")
  op getUserById(@path userId: string): {
    @statusCode statusCode: 200;
    @body user: User;
  };

  // Модель пользователя
  model User {
    // ID пользователя
    @format("uuid")
    id: string;

    // Имя пользователя
    @minLength(1)
    @example("John")
    firstName: string;

    // Фамилия пользователя
    @minLength(1)
    @example("Doe")
    lastName: string;

    // Возраст пользователя
    @minValue(0)
    @example(25)
    age: int32;

    // Пол пользователя
    @example(UserSexType.MALE)
    sex: UserSexType;
  }

  // Перечисление возможных полов пользователя
  enum UserSexType {
    MALE: "Мужской",
    FEMALE: "Женский",
  }
}
```

Запустить компиляцию
```bash
$ tsp compile .
TypeSpec compiler v0.62.0
Compilation completed successfully.
```

#### tsp-output/@typespec/openapi3/openapi.yaml
Сгенерированный файл в формате спецификации OAS3.
```yaml
openapi: 3.0.0
info:
  title: Users API
  version: 0.0.0
tags:
  - name: Users
paths:
  /users:
    get:
      operationId: Users_getUsersRegistry
      summary: Возвращает список пользователей
      parameters: []
      responses:
        '200':
          description: The request has succeeded.
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Users.User'
      tags:
        - Users
  /users/{userId}:
    get:
      operationId: Users_getUserById
      summary: Возвращает пользователя по его ID
      parameters:
        - name: userId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: The request has succeeded.
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Users.User'
      tags:
        - Users
components:
  schemas:
    Users.User:
      type: object
      required:
        - id
        - firstName
        - lastName
        - age
        - sex
      properties:
        id:
          type: string
          format: uuid
        firstName:
          type: string
          example: John
          minLength: 1
        lastName:
          type: string
          example: Doe
          minLength: 1
        age:
          type: integer
          format: int32
          example: 25
          minimum: 0
        sex:
          allOf:
            - $ref: '#/components/schemas/Users.UserSexType'
          example: Мужской
    Users.UserSexType:
      type: string
      enum:
        - Мужской
        - Женский
servers:
  - url: https://example.com
    description: Single server endpoint
    variables: {}
```

## IMHO
- При наличии базовых знаний TypeScript, порог вхождения в язык будет низким. 
- Выглядит так, что хочется его использовать в качестве источника правды при Contract-first-подходе.
- Эмиттеры одновременно в OAS3 и JSON Schema закрывают вопросы дублирования валидаций моделей.
- Активные [дискуссии на GitHub](https://github.com/microsoft/typespec/discussions) позволяют найти ответы на типовые вопросы.
