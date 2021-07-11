<template>
  <div>
    <input v-model="inputValue">
    <button v-on:click="handleClick">
      ToDoを追加
    </button>
    <input
            v-model="firstValue"
            placeholder="フィルタテキスト"
            >
            <ul>
              <li
            v-for="todo in filterdTodoItems"
            v-bind:key="todo.id"
            class="todo-item"
            v-bind:class="{'done': todo.done}"
            v-on:click="todo.done = !todo.done">
                <span v-if="todo.done">✔︎</span>
                {{ todo.text }}
              </li>
            </ul>
  </div>
</template>

<script>
export default {
  data() {
    const todoItems = [
    ]
    return {
      inputValue: '',
      todoItems,
      firstValue: '',
    }
  },
  computed: {
    filterdTodoItems() {
      if (!this.firstValue) {
        return this.todoItems
      }
      return this.todoItems.filter((todo) => {
        return todo.text.includes(this.firstValue)
      })
    }
  },
  methods: {
    handleClick() {
      this.todoItems.push({
        id: this.todoItems.length + 1,
        done: false,
        text: this.inputValue
      })
      this.inputValue = ''
    },
  }
}
</script>
<style>
.todo-item.done{
  background-color: #3fb983;
  color: #ffffff;
}
</style>
