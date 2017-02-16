<template>
  <div id="todos">
    <div>
      <input
        v-model="todoDescription"
        @keyup.enter="addTodo"
        placeholder="Type todo"
      >
    </div>
    <ul>
      <todo-item
        v-for="(todo, index) in todos"
        :item="todo" :index="index"
        @remove="removeTodo"
      />
    </ul>
  </div>
</template>

<script>
import TodoItem from './TodoItem'

export default {
  name: 'todos',
  components: {
    TodoItem
  },
  props: {
    todos: Array
  },
  data: function () {
    return { todoDescription: '' }
  },
  methods: {
    addTodo: function () {
      this.$emit('add-todo', this.todoDescription)
      this.todoDescription = ''
    },
    removeTodo: function (idx) {
      this.$emit('remove-todo', idx)
    }
  }
}
</script>

<style>
</style>
