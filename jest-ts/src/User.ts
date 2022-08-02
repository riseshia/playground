import SomeClient from "./SomeClient"

interface UserAttrs {
  id: number;
  name: string;
}

class User {
  id: number
  name: string

  constructor({ id, name }: UserAttrs) {
    this.id = id
    this.name = name
  }

  static find(id: number): User {
    return new User(SomeClient.find_by_id(id))
  }
}

export default User
