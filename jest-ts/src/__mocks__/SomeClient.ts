const database = [
  { id: 1, name: "John11" },
  { id: 2, name: "Sara11" },
  { id: 3, name: "Bill11" }
]

const find_by_id = (id: number) => {
  return database[id - 1]
}

export default { find_by_id }
