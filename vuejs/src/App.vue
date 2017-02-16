<template>
  <div id="app">
    <todos
      :todos="todos"
      @add-todo="addTodo"
      @remove-todo="removeTodo"
    />
  </div>
</template>

<script>
import Todos from './components/Todos'

export default {
  name: 'app',
  components: {
    Todos
  },
  data: function () {
    return {
      todos: [
        'todo1',
        'todo2'
      ]
    }
  },
  methods: {
    addTodo: function (item) {
      this.todos.unshift(item)
    },
    removeTodo: function (index) {
      this.todos.splice(index, 1)
    }
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
