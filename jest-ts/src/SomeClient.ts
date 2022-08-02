const database = [
  { id: 1, name: "John" },
  { id: 2, name: "Sara" },
  { id: 3, name: "Bill" }
]

const find_by_id = (id: number) => {
  return database[id - 1]
}

export default { find_by_id }
