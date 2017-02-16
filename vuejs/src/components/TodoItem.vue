<template>
  <li>{{ item }} <button v-on:click="$emit('remove', index)">X</button></li>
</template>

<script>
export default {
  name: 'todo-item',
  props: {
    item: String,
    index: Number
  },
  methods: {
    remove: function () {
      console.log('remove called')
    }
  }
}
</script>

<style>
</style>
