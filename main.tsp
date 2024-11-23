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
