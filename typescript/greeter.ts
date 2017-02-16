class Student {
  fullName: string;
  constructor(public firstName, public middleInitial, public lastName) {
    this.fullName = firstName + " " + middleInitial + " " + lastName;
  }
}

var student = new Student("Jane", "M.", "User");

interface Person {
  firstName: string;
  lastName: string;
}

function greeter(person: Person) {
  return "Hello, " + person;
}

var user = {
  firstName: "Jane",
  lastName: "User"
};

document.body.innerHTML = greeter(user);

interface Options {
  color: string,
  volume: number
}

let options = {} as Options;

options.color = "red";
options.volume = 11;
